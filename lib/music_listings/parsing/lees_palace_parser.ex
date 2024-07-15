defmodule MusicListings.Parsing.LeesPalaceParser do
  @moduledoc """
  Parser for extracing events from https://www.leespalace.com/
  """
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser

  @impl true
  def source_url, do: "https://www.leespalace.com/events"

  @impl true
  def venue_name, do: "Lee's Palace"

  @impl true
  def example_data_file_location, do: "test/data/lees_palace/index.html"

  @impl true
  def event_selector(body) do
    Parser.event_selector(body, ".schedule-event")
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
    event_date = event |> event_date() |> Date.to_string()

    "#{event_title}_#{event_date}"
  end

  @impl true
  def event_title(event) do
    Parser.event_title(event, ".schedule-speaker-name")
  end

  @impl true
  def performers(event) do
    Parser.performers(event, ".schedule-speaker-name")
  end

  @impl true
  def event_date(event) do
    full_date_string =
      event
      |> Meeseeks.one(css(".schedule-event-time"))
      |> Meeseeks.text()

    [_day_of_week_string, month_string, day_string, year_string] = String.split(full_date_string)

    day = day_string |> String.replace(",", "") |> String.to_integer()
    month = Parser.convert_month_string_to_number(month_string)
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
    |> Parser.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Meeseeks.one(css(".non"))
    |> Meeseeks.text()
    |> Parser.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Parser.ticket_url(event, ".blb")
  end
end
