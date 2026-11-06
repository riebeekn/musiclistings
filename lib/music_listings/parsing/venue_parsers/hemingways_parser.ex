defmodule MusicListings.Parsing.VenueParsers.HemingwaysParser do
  @moduledoc """
  Parser for extracting events from https://hemingways.to/events

  The site is on Sociavore and renders all of its events into one page.  Only
  the cards in the "Live Music" category are of interest, the rest are sports,
  trivia and the like.  Posts are copied from older ones, so a slug can name some
  other act or even another kind of event: go by the category and the numeric id.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://hemingways.to"
  @title_prefix_regex ~r/^live music\s*[-–—:]\s*/i

  @impl true
  def source_url, do: "#{@base_url}/events"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".event-container[data-events-category*='Live Music']"))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    [_path, id] = Regex.run(~r{^/events/(\d+)/}, event_path(event))
    id
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".event__title"))
    |> String.replace(@title_prefix_regex, "")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week, month_string, day_string | _times] = date_parts(event)

    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
    date
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event) do
    [_day_of_week, _month_string, _day_string | times] = date_parts(event)

    times
    |> List.first()
    |> ParseHelpers.time_from_time_string()
  end

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(event), do: "#{@base_url}#{event_path(event)}"

  # i.e. "Friday, Nov 06  9:00pm - 11:45pm"
  defp date_parts(event) do
    event
    |> Selectors.text(css(".event__date"))
    |> String.split()
  end

  defp event_path(event) do
    event
    |> Selectors.url(css("a.event__title"))
    |> String.trim_trailing("?")
  end
end
