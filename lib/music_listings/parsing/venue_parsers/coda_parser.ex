defmodule MusicListings.Parsing.VenueParsers.CodaParser do
  @moduledoc """
  Parser for extracing events from https://www.codatoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.codatoronto.com/events"

  @impl true
  def example_data_file_location, do: "test/data/coda/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".schedule-event"))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    # combine date and title
    event_title = event |> event_title() |> String.downcase() |> String.replace(" ", "")
    event_date = event |> event_date()

    "#{event_title}_#{event_date}"
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
    full_date_string =
      event
      |> Meeseeks.one(css(".event-date"))
      |> Meeseeks.text()

    [month_string, day_string, year_string] = String.split(full_date_string)

    day = day_string |> String.replace(",", "") |> String.to_integer()
    month = ParseHelpers.convert_month_string_to_number(month_string)
    year = String.to_integer(year_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(_event) do
    ParseHelpers.convert_price_string_to_price(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(_event) do
    nil
  end
end
