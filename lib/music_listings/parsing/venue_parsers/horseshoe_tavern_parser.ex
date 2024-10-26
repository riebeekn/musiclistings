defmodule MusicListings.Parsing.VenueParsers.HorseshoeTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.horseshoetavern.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.horseshoetavern.com/events"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/horseshoe_tavern/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".schedule-event"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("horseshoe_tavern", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".schedule-speaker-name"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".schedule-speaker-name"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    full_date_string = Selectors.text(event, css(".schedule-event-time"))

    [_day_of_week, day_month_string, year_string] = String.split(full_date_string, ", ")
    [month_string, day_string] = String.split(day_month_string)

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.all_matches(css(".schedule-event-time"))
    |> Selectors.text()
    |> Enum.find(fn element -> element |> String.contains?("pm") end)
    |> ParseHelpers.build_time_from_time_string()
  end

  @impl true
  def price(event) do
    event
    |> Selectors.all_matches(css(".schedule-event-time"))
    |> Selectors.text()
    |> Enum.find(fn element -> element |> String.contains?("$") end)
    |> Price.new()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Selectors.text(css(".non"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".blb"))
  end

  @impl true
  def details_url(event) do
    slug = Selectors.url(event, css(".schedule-speaker"))
    "https://www.horseshoetavern.com#{slug}"
  end
end
