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
    Selectors.url(body, css(".pagination .older a"))
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".event-title a"))
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
      |> Selectors.text(css(".event-date"))
      |> String.split(", ")

    [month_string, day_string] = String.split(month_day_string)

    ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
  end

  @impl true
  def event_time(event) do
    [_day_of_week_string, _month_day_string, doors_string] =
      event
      |> Selectors.text(css(".event-date"))
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
    |> Selectors.text(css(".event-ages"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".event-title a"))
  end
end
