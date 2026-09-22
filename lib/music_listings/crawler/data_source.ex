defmodule MusicListings.Crawler.DataSource do
  @moduledoc """
  Recursively consumes html files from the internet
  and parses these files into a list of Payloads containing the
  html for individual events in the form of a Meeseeks result
  """
  alias MusicListings.Crawler.Payload
  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.VenueParser

  require Logger

  @typedoc """
  Why retrieval stopped early.  The type doubles as the `CrawlError` type:

    * `:fetch_error` - the page never came back as a 200: a non-200 status, a
      transport failure (e.g. a timeout from an origin that drops Render's IP),
      or a crash inside the parser's `retrieve_events_fun`.
    * `:page_parse_error` - the page was fetched but the parser's `events/1` or
      `next_page_url/2` blew up on it.
  """
  @type error :: {:fetch_error | :page_parse_error, message :: String.t()}

  @doc """
  Retrieves every page of events for the parser, starting at `url`.

  A failure on a later page doesn't discard the pages already retrieved - they
  come back alongside the error so the crawl can still store them.
  """
  @spec retrieve_events(
          parser :: VenueParser,
          url :: String.t(),
          events :: list(Payload)
        ) :: {:ok, list(Payload)} | {:error, error(), list(Payload)}
  def retrieve_events(parser, url, payloads \\ []) do
    with {:ok, body} <- fetch(parser, url),
         {:ok, events, next_page_url} <- parse_page(parser, body, url) do
      payloads = payloads ++ Enum.map(events, &Payload.new/1)

      if next_page_url do
        retrieve_events(parser, next_page_url, payloads)
      else
        {:ok, payloads}
      end
    else
      {:error, {_type, message} = error} ->
        Logger.error(message)
        {:error, error, payloads}
    end
  end

  defp fetch(parser, url) do
    case parser.retrieve_events_fun().(url) do
      {:ok, %Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Response{status: status, body: body}} ->
        # Without the body we can't tell a bot-mitigation challenge page from an
        # empty block, and the crawl only runs nightly - so log enough to
        # diagnose it the first time.
        Logger.warning("Body of HTTP #{status} from #{url}: #{body_snippet(body)}")
        {:error, {:fetch_error, "HTTP #{status} from #{url}"}}

      {:error, reason} ->
        {:error, {:fetch_error, "Request to #{url} failed: #{describe(reason)}"}}

      other ->
        {:error, {:fetch_error, "Unexpected response from #{url}: #{inspect(other, limit: 5)}"}}
    end
  rescue
    error ->
      {:error, {:fetch_error, "Request to #{url} crashed: #{Exception.message(error)}"}}
  end

  defp parse_page(parser, body, url) do
    case parser.events(body) do
      {:error, reason} ->
        {:error, {:page_parse_error, "Failed to parse #{url}: #{describe(reason)}"}}

      events ->
        # Forced here so a lazy enumerable that blows up is caught below
        events = Enum.to_list(events || [])
        {:ok, events, parser.next_page_url(body, url)}
    end
  rescue
    error ->
      {:error,
       {:page_parse_error,
        "Failed to parse #{url}: " <> Exception.format(:error, error, __STACKTRACE__)}}
  end

  defp describe(reason) when is_exception(reason), do: Exception.message(reason)
  defp describe(reason), do: inspect(reason)

  # `inspect/2` because the body is a decoded map for the JSON-API venues, not
  # always a binary.
  defp body_snippet(body), do: inspect(body, printable_limit: 500, limit: 20)
end
