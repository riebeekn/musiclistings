defmodule MusicListings.Parsing.VenueParsers.CodaParser do
  @moduledoc """
  Parser for extracing events from https://www.codatoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.codatoronto.com/events"

  @impl true
  def retrieve_events_fun do
    fn url -> Req.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/coda/index.html"

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
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".event-name"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".event-name"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    full_date_string = Selectors.text(event, css(".event-date"))
    [month_string, day_string, year_string] = String.split(full_date_string)

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(_event) do
    nil
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
    slug = Selectors.url(event, css(".link-block"))
    "https://www.codatoronto.com#{slug}"
  end
end
