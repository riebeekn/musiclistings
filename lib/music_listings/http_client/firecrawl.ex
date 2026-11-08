defmodule MusicListings.HttpClient.Firecrawl do
  @moduledoc """
  Fetches a URL through Firecrawl's scrape API (https://docs.firecrawl.dev), which
  loads the page in a real browser on Firecrawl's own IPs and hands back the
  rendered HTML.

  The mhrth.com venues (Massey Hall, Roy Thomson Hall, TD Music Hall) sit behind a
  Cloudflare challenge keyed on bot score. A real Chrome fingerprint gets through
  from a residential IP but not from Render's, so those venues are fetched through
  Firecrawl instead. So is Linsmore Tavern, whose host challenges Render's IP, and
  918 Bathurst, whose events page is filled in by JavaScript.
  See `MusicListings.HttpClient.Req` for how to opt a request in (`firecrawl: true`).

  Because the page is rendered, content a site fills in with JavaScript is in
  the HTML - which is what lets `MhRthTdmhParser` read an event's showings off
  its details page rather than call the API behind it.

  The response's `status` is the one the *target* site answered with
  (Firecrawl's `metadata.statusCode`), so a challenged page still comes back as
  a `403`. A request Firecrawl itself couldn't carry out is an `{:error, _}`.

  Request headers are not passed on: the browser sends its own.

  Authenticates with `:firecrawl_api_key` (`$FIRECRAWL_API_KEY`) when set.
  Firecrawl also serves unauthenticated requests, so a missing key still works,
  at whatever rate Firecrawl allows anonymous use.
  """

  alias MusicListings.HttpClient.Response

  @endpoint "https://api.firecrawl.dev/v2/scrape"

  # A browser load is far slower than a plain GET
  @default_receive_timeout :timer.minutes(2)

  # Statuses from Firecrawl's own API, not the target's.  A failed scrape isn't
  # charged, so a retry costs nothing but time.
  @retry_statuses [408, 429, 500, 502, 503, 504]
  @default_max_retries 2
  @max_retry_delay_ms :timer.seconds(30)

  # Firecrawl's scrape rate limit is per minute, and a 429 says to retry when
  # the window resets (e.g. "retry after 12s") - a backoff of a second or two
  # just burns the retries inside the same window.  So a 429 waits for the
  # `Retry-After` header when there is one, otherwise for a whole window.
  @rate_limit_window_ms :timer.minutes(1)

  @doc """
  Scrapes `url`. Honours `:receive_timeout` and `:max_retries`, as the Req
  client does.
  """
  @spec get(String.t(), keyword()) :: {:ok, Response.t()} | {:error, any()}
  def get(url, opts \\ []) do
    [
      json: %{url: url, formats: ["rawHtml"], maxAge: 0},
      headers: auth_headers(),
      receive_timeout: Keyword.get(opts, :receive_timeout, @default_receive_timeout),
      retry: &retry?/2,
      max_retries: Keyword.get(opts, :max_retries, @default_max_retries)
    ]
    |> Keyword.merge(Application.get_env(:music_listings, :firecrawl_req_options, []))
    |> then(&Req.post(@endpoint, &1))
    |> case do
      {:ok,
       %Req.Response{
         body: %{
           "success" => true,
           "data" => %{"rawHtml" => html, "metadata" => %{"statusCode" => status}}
         }
       }} ->
        {:ok, Response.new(status, html)}

      {:ok, %Req.Response{status: status, body: %{"error" => error}}} ->
        {:error, {:firecrawl_failed, status, error}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:firecrawl_failed, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp auth_headers do
    case Application.get_env(:music_listings, :firecrawl_api_key) do
      key when is_binary(key) and key != "" -> [authorization: "Bearer #{key}"]
      _no_key -> []
    end
  end

  # As MusicListings.HttpClient.Req: a bounded backoff of our own rather than
  # Req's, which obeys an uncapped `Retry-After`.
  defp retry?(_request, %Req.Response{status: 429} = response) do
    {:delay, rate_limit_delay(response)}
  end

  defp retry?(request, %Req.Response{status: status}) when status in @retry_statuses do
    {:delay, retry_delay(request)}
  end

  defp retry?(request, %Req.TransportError{}), do: {:delay, retry_delay(request)}
  defp retry?(_request, _response), do: false

  defp retry_delay(request) do
    retry_count = Req.Request.get_private(request, :req_retry_count, 0)
    base_delay = Application.get_env(:music_listings, :firecrawl_retry_base_delay_ms, 1_000)
    min(Integer.pow(2, retry_count) * base_delay, @max_retry_delay_ms)
  end

  defp rate_limit_delay(response) do
    window_ms =
      Application.get_env(:music_listings, :firecrawl_rate_limit_window_ms, @rate_limit_window_ms)

    with [value | _rest] <- Req.Response.get_header(response, "retry-after"),
         {seconds, ""} <- value |> String.trim() |> Integer.parse() do
      # A second over, so the retry lands after the reset rather than on it
      min(:timer.seconds(seconds + 1), window_ms)
    else
      _no_usable_header -> window_ms
    end
  end
end
