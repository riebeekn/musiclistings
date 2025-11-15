defmodule MusicListings.Parsing.VenueParsers.SneakyDeesParser do
  @moduledoc """
  Parser for extracting events from https://www.sneakydees.com/events-copy
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.sneakydees.com/events-copy"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/sneaky_dees/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".events-collection-item"))
    |> Enum.filter(&live_music_event?/1)
  end

  defp live_music_event?(event) do
    category = Selectors.text(event, css(".text-block-4"))
    category == "Live Music"
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

    ParseHelpers.build_id_from_venue_and_datetime("sneaky_dees", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".events-heading"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    date_string = Selectors.text(event, css(".date"))
    # Date format: "Nov 15, 2025"
    [month_string, day_year_string] = String.split(date_string, " ", parts: 2)
    [day_string, year_string] = String.split(day_year_string, ", ")

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css(".time"))
    |> ParseHelpers.build_time_from_time_string()
  end

  @impl true
  def price(_event) do
    Price.new(nil)
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".event-card-link-block"))
  end

  @impl true
  def details_url(event) do
    # The ticket URL is also the details URL for this venue
    ticket_url(event)
  end
end
