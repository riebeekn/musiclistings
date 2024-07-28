defmodule MusicListings.Parsing.VenueParsers.PhoenixParser do
  @moduledoc """
  Parser for extracing events from https://thephoenixconcerttheatre.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://thephoenixconcerttheatre.com/events"

  @impl true
  def example_data_file_location, do: "test/data/phoenix/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".event-item"))
  end

  @impl true
  def next_page_url(body) do
    body
    |> Meeseeks.one(css(".pagination .older a"))
    |> Meeseeks.attr("href")
  end

  @impl true
  def event_id(event) do
    title_slug = event |> event_title() |> String.replace(" ", "")
    "#{title_slug}-#{event_date(event)}"
  end

  @impl true
  def event_title(event) do
    event
    |> Meeseeks.one(css(".event-title a"))
    |> Meeseeks.text()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week_string, month_day_string, _doors_string] =
      event
      |> Meeseeks.one(css(".event-date"))
      |> Meeseeks.text()
      |> String.split(", ")

    [month_string, day_string] = String.split(month_day_string)

    day = String.to_integer(day_string)
    month = ParseHelpers.convert_month_string_to_number(month_string)

    today = Date.utc_today()
    Date.new!(today.year, month, day)
  end

  @impl true
  def event_time(event) do
    [_day_of_week_string, _month_day_string, doors_string] =
      event
      |> Meeseeks.one(css(".event-date"))
      |> Meeseeks.text()
      |> String.split(", ")

    doors_string
    |> String.replace("Doors: ", "")
    |> ParseHelpers.time_string_to_time()
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Meeseeks.one(css(".event-ages"))
    |> Meeseeks.text()
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".event-title a"))
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
