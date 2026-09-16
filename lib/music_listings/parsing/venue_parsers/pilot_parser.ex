defmodule MusicListings.Parsing.VenueParsers.PilotParser do
  @moduledoc """
  Parser for extracing events from https://thepilot.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://thepilot.ca"
  @event_card_selector ".post.post_style_2"
  @title_selector "a.post__title"
  @ld_json_selector "script[type=\"application/ld+json\"]"

  # The numeric CMS id in the path - each occurrence of a recurring event
  # gets its own - keys the event, so editing a title or time on the site
  # doesn't produce a duplicate here.
  @event_path_regex ~r{^/events/(\d+)/}

  # The "startDate" is stamped "+0000" but is really the local wall clock time
  # (a 7:00pm show is written "T19:00:00+0000"), so the zone is dropped rather
  # than converted.  Erlang's ISO parser also wants a colon in the offset.
  @start_date_offset_regex ~r/([+-])(\d{2})(\d{2})$/

  @impl true
  def source_url, do: "https://www.thepilot.ca/events"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(@event_card_selector))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    [_match, cms_id] = Regex.run(@event_path_regex, event_path(event))

    "pilot_#{cms_id}"
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(@title_selector))
    |> ParseHelpers.fix_encoding()
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> start_datetime()
    |> DateTime.to_date()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> start_datetime()
    |> DateTime.to_time()
    |> Map.put(:second, 0)
  end

  # The event page is fetched once per event and memoized: every callback for a
  # given event runs in the same task process (see Crawler.EventParser), so the
  # date and the time cost a single request between them.
  defp start_datetime(event) do
    url = details_url(event)
    cache_key = {:pilot_detail, url}

    case Process.get(cache_key) do
      nil ->
        datetime = fetch_start_datetime(url)
        Process.put(cache_key, datetime)
        datetime

      cached ->
        cached
    end
  end

  defp fetch_start_datetime(url) do
    with {:ok, %HttpClient.Response{status: 200, body: body}} <- HttpClient.get(url),
         {:ok, datetime} <- extract_start_datetime(body) do
      datetime
    else
      _error ->
        # Deliberately fail rather than fall back to a guess: a fabricated date
        # publishes a show that isn't happening, which is worse than missing it.
        # The raise is recorded as a parse error and surfaced in the crawl email.
        raise "Unable to determine event date for #{url}"
    end
  end

  defp extract_start_datetime(body) do
    body
    |> Selectors.all_matches(css(@ld_json_selector))
    |> Enum.find_value(:error, fn script ->
      with json when is_binary(json) <- Selectors.data(script),
           {:ok, %{"@type" => "Event", "startDate" => start_date}} <-
             json |> remove_trailing_commas() |> Jason.decode(),
           {:ok, datetime, _offset} <- start_date |> fix_offset() |> DateTime.from_iso8601() do
        {:ok, datetime}
      else
        _not_the_event -> nil
      end
    end)
  end

  defp fix_offset(start_date) do
    Regex.replace(@start_date_offset_regex, start_date, "\\1\\2:\\3")
  end

  # The template leaves a trailing comma behind an omitted optional field
  defp remove_trailing_commas(json) do
    Regex.replace(~r/,\s*([\]}])/m, json, "\\1")
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(event) do
    @base_url <> event_path(event)
  end

  # The title link's href ends in a stray "?" (an empty query string the
  # template leaves behind) so it is dropped rather than published.
  defp event_path(event) do
    event
    |> Selectors.url(css(@title_selector))
    |> String.trim_trailing("?")
  end
end
