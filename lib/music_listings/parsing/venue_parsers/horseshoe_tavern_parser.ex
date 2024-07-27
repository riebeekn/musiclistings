defmodule MusicListings.Parsing.VenueParsers.HorseshoeTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.horseshoetavern.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers

  @impl true
  def source_url, do: "https://www.horseshoetavern.com/events"

  @impl true
  def example_data_file_location, do: "test/data/horseshoe_tavern/index.html"

  @impl true
  def events(body) do
    ParseHelpers.event_selector(body, ".schedule-event")
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event_title = ParseHelpers.event_title(event, ".schedule-speaker-name")
    event_date = event_date(event)
    "#{event_title |> String.replace(" ", "") |> String.downcase()}-#{event_date}"
  end

  @impl true
  def event_title(event) do
    ParseHelpers.event_title(event, ".schedule-speaker-name")
  end

  @impl true
  def performers(event) do
    ParseHelpers.performers(event, ".schedule-speaker-name")
  end

  @impl true
  def event_date(event) do
    full_date_string =
      event
      |> Meeseeks.one(css(".schedule-event-time"))
      |> Meeseeks.text()

    [_day_of_week, day_month_string, year_string] = String.split(full_date_string, ", ")
    [month_string, day_string] = String.split(day_month_string)

    day = String.to_integer(day_string)
    month = ParseHelpers.convert_month_string_to_number(month_string)
    year = String.to_integer(year_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.all(css(".schedule-event-time"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("pm") end)
    |> Meeseeks.text()
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(event) do
    event
    |> Meeseeks.all(css(".schedule-event-time"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("$") end)
    |> Meeseeks.text()
    |> ParseHelpers.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Meeseeks.one(css(".non"))
    |> Meeseeks.text()
    |> ParseHelpers.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    ParseHelpers.ticket_url(event, ".blb")
  end
end
