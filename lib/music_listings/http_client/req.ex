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

  @impl true
  def get(url, headers \\ []) do
    url
    |> Req.get(
      headers: headers,
      finch: MusicListings.ReqFinch,
      receive_timeout: 30_000,
      retry: &retry?/2,
      max_retries: 3
    )
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def post(url, body, headers) do
    url
    |> Req.post(
      headers: headers,
      json: body,
      finch: MusicListings.ReqFinch,
      receive_timeout: 30_000,
      retry: &retry?/2,
      max_retries: 3
    )
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
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
