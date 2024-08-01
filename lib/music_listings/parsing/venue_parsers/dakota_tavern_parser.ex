defmodule MusicListings.Parsing.VenueParsers.DakotaTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.dakotatavern.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.dakotatavern.ca"

  @impl true
  def example_data_file_location, do: "test/data/dakota_tavern/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".grid-item"))
  end

  @impl true
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def event_title(event) do
    [_date, title] =
      event
      |> Selectors.text(css(".portfolio-title"))
      |> String.split("-")

    title |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [date, _title] =
      event
      |> Selectors.text(css(".portfolio-title"))
      |> String.split("-")

    [_day_of_week, month_and_day_string, year_string] = String.split(date, ",")

    [month_string, day_string] = month_and_day_string |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
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
    event_url = Selectors.url(event, css(".grid-item"))

    "#{source_url()}#{event_url}"
  end
end
