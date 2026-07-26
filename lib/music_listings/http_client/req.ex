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

  # Suit a venue page: quick to answer, and worth several attempts because a
  # venue that fails is a venue whose events we lose for the night. Callers with
  # a slower endpoint override these per request - see `request_options/2`.
  @default_receive_timeout :timer.seconds(30)
  @default_max_retries 3

  @impl true
  def get(url, headers \\ [], opts \\ []) do
    url
    |> Req.get(request_options(headers, opts))
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def post(url, body, headers) do
    url
    |> Req.post([json: body] ++ request_options(headers, []))
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  # Only the two tunables a caller has ever needed are overridable; the retry
  # policy itself stays here so every request in the app backs off the same way.
  defp request_options(headers, opts) do
    [
      headers: headers,
      compressed: true,
      finch: MusicListings.ReqFinch,
      receive_timeout: Keyword.get(opts, :receive_timeout, @default_receive_timeout),
      retry: &retry?/2,
      max_retries: Keyword.get(opts, :max_retries, @default_max_retries)
    ]
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
