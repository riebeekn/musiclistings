defmodule MusicListings.HttpClient.Req do
  @moduledoc """
  Req HttpClient implementation
  """
  @behaviour MusicListings.HttpClient

  alias MusicListings.HttpClient.Response

  @retry_statuses [403, 408, 429, 500, 502, 503, 504]

  # Cap on a single retry sleep. We do NOT honour the server's `Retry-After`
  # header: Req obeys it verbatim and uncapped (a 503 with `Retry-After: 86400`
  # would block the crawler for ~24h). Instead we return `{:delay, ms}` from
  # retry?/2 so Req uses our bounded exponential backoff and ignores the header.
  @max_retry_delay_ms :timer.seconds(30)

  # Callers can override any of these; note we deliberately do NOT
  # default `content-type`, since post/3 passes `json:` and Req's json step owns that header.
  @default_headers [
    {"user-agent",
     "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"},
    {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
    {"accept-language", "en-CA,en;q=0.9"}
  ]

  @doc """
  Browser-like default request headers. Exposed so multi-step flows built
  directly on Req (e.g. `MusicListings.HttpClient.SiteGroundChallenge`) present
  the same fingerprint as the normal client.
  """
  @spec default_headers() :: [{String.t(), String.t()}]
  def default_headers, do: @default_headers

  @impl true
  def get(url, headers \\ []) do
    url
    |> Req.get(request_options(headers))
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def post(url, body, headers) do
    url
    |> Req.post([json: body] ++ request_options(headers))
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  defp request_options(headers) do
    [
      headers: merge_headers(headers),
      compressed: true,
      finch: MusicListings.ReqFinch,
      receive_timeout: 30_000,
      retry: &retry?/2,
      max_retries: 3
    ] ++ Application.get_env(:music_listings, :req_options, [])
  end

  # Caller-supplied headers win over @default_headers, matched case-insensitively
  # on the header name so a caller's "User-Agent" replaces our "user-agent"
  # rather than being sent alongside it.
  defp merge_headers(headers) do
    overridden = MapSet.new(headers, fn {name, _value} -> String.downcase(name) end)

    Enum.reject(@default_headers, fn {name, _value} ->
      MapSet.member?(overridden, String.downcase(name))
    end) ++ headers
  end

  # A 202 to a page GET is not a real "Accepted" — it's bot mitigation handing
  # back a placeholder. Worth retrying. Scoped to GET because 202 is a
  # legitimate success for the async POST APIs we call.
  defp retry?(%{method: :get} = request, %{status: 202}) do
    {:delay, retry_delay(request)}
  end

  defp retry?(request, %{status: status}) when status in @retry_statuses do
    {:delay, retry_delay(request)}
  end

  defp retry?(request, %Req.TransportError{}), do: {:delay, retry_delay(request)}
  defp retry?(_request, _response), do: false

  # Bounded exponential backoff (1s, 2s, 4s, ... capped at @max_retry_delay_ms).
  # `:req_retry_count` is Req's own internal attempt counter.
  defp retry_delay(request) do
    retry_count = Req.Request.get_private(request, :req_retry_count, 0)
    min(Integer.pow(2, retry_count) * 1_000, @max_retry_delay_ms)
  end
end
