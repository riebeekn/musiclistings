defmodule MusicListings.Parsing.VenueParsers.VelvetUndergroundParser do
  @moduledoc """
  Parser for extracing events from https://thevelvet.ca
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers

  @impl true
  def source_url, do: "https://thevelvet.ca/events"

  @impl true
  def example_data_file_location, do: "test/data/velvet_underground/index.html"

  @impl true
  def event(body) do
    ParseHelpers.event_selector(body, ".event-block")
  end

  @impl true
  def next_page_url(body) do
    ParseHelpers.next_page_url(body, ".nav-previous a")
  end

  @impl true
  def event_id(event) do
    ParseHelpers.event_id(event, ".event-block")
  end

  @impl true
  def event_title(event) do
    ParseHelpers.event_title(event, ".event-title")
  end

  @impl true
  def performers(event) do
    ParseHelpers.performers(event, ".event-artist-name")
  end

  @impl true
  def event_date(event) do
    date_string =
      event
      |> Meeseeks.one(css(".event-block"))
      |> Meeseeks.Result.attr("data-event-date")

    year = date_string |> String.slice(0..3) |> String.to_integer()
    month = date_string |> String.slice(4..5) |> String.to_integer()
    day = date_string |> String.slice(6..7) |> String.to_integer()

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(0)
    |> String.split(" ")
    |> Enum.at(1)
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Price:") end)
    |> Meeseeks.text()
    |> ParseHelpers.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(1)
    |> String.split(":")
    |> Enum.at(1)
    |> ParseHelpers.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    ParseHelpers.ticket_url(event, ".event-ticket-link")
  end
end
