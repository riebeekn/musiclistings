defmodule MusicListings.Parsing.VenueParsers.GreatHallParser do
  @moduledoc """
  Parser for extracing events from https://thegreathall.ca
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers

  @impl true
  def source_url, do: "https://thegreathall.ca/calendar"

  @impl true
  def example_data_file_location, do: "test/data/great_hall/index.html"

  @impl true
  def event_selector(body) do
    ParseHelpers.event_selector(body, ".tgh-event-item-container")
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    class_attr = Meeseeks.attr(event, "class")
    regex = ~r/event-(?<event_id>\d+)/

    %{"event_id" => event_id} = Regex.named_captures(regex, class_attr)
    event_id
  end

  @impl true
  def event_title(event) do
    ParseHelpers.event_title(event, ".tgh-e-title")
  end

  @impl true
  def performers(event) do
    ParseHelpers.performers(event, ".tgh-e-title")
  end

  @impl true
  def event_date(event) do
    full_date_string =
      event
      |> Meeseeks.one(css(".tgh-e-date"))
      |> Meeseeks.text()

    [_day_of_week_string, month_string, day_string, year_string] = String.split(full_date_string)

    day = String.to_integer(day_string)
    month = ParseHelpers.convert_month_string_to_number(month_string)
    year = String.to_integer(year_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.one(css(".tgh-e-time"))
    |> Meeseeks.text()
    |> ParseHelpers.convert_event_time_string_to_time()
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
