defmodule MusicListings.Parsing.VenueParsers.LeesPalaceParser do
  @moduledoc """
  Parser for extracing events from https://www.leespalace.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.leespalace.com/events"

  @impl true
  def example_data_file_location, do: "test/data/lees_palace/index.html"

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
    full_date_string =
      event
      |> Meeseeks.one(css(".schedule-event-time"))
      |> Meeseeks.text()

    [_day_of_week_string, month_string, day_string, year_string] = String.split(full_date_string)

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
  def price(event) do
    event
    |> Meeseeks.all(css(".schedule-event-time"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("$") end)
    |> Meeseeks.text()
    |> Price.new()
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
    Selectors.url(event, css(".blb"))
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
