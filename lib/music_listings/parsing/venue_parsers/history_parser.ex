defmodule MusicListings.Parsing.VenueParsers.HistoryParser do
  @moduledoc """
  Parser for extracing events from https://www.historytoronto.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.historytoronto.com/events/events_ajax/0?per_page=60"

  @impl true
  def example_data_file_location, do: "test/data/history/index.html"

  @impl true
  def events(body) do
    body
    |> ParseHelpers.clean_html()
    |> Selectors.all_matches(css(".eventItem"))
  end

  @impl true
  def next_page_url(_body) do
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
    Selectors.text(event, css(".title"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".title"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    day_string = Selectors.text(event, css(".m-date__day"))
    month_string = Selectors.text(event, css(".m-date__month"))
    year_string = Selectors.text(event, css(".m-date__year"))

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css(".start"))
    |> ParseHelpers.time_string_to_time()
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
  def ticket_url(event) do
    Selectors.url(event, css(".tickets"))
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".more"))
  end
end
