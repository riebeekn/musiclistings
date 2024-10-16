defmodule MusicListings.Parsing.VenueParsers.VelvetUndergroundParser do
  @moduledoc """
  Parser for extracing events from https://thevelvet.ca
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://thevelvet.ca/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HTTPoison.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/velvet_underground/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".event-block"))
  end

  @impl true
  def next_page_url(body, _current_url) do
    Selectors.url(body, css(".nav-previous a"))
  end

  @impl true
  def event_id(event) do
    Selectors.id(event, css(".event-block"))
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".event-title"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".event-artist-name"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    date_string = Selectors.attr(event, "data-event-date")

    year_string = String.slice(date_string, 0..3)
    month_string = String.slice(date_string, 4..5)
    day_string = String.slice(date_string, 6..7)

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.all_matches(css(".event-meta"))
    |> Selectors.text()
    |> Enum.find(fn element -> element |> String.contains?("Ages:") end)
    |> String.split("|")
    |> Enum.at(0)
    |> String.split(" ")
    |> Enum.at(1)
    |> ParseHelpers.build_time_from_time_string()
  end

  @impl true
  def price(event) do
    event
    |> Selectors.all_matches(css(".event-meta"))
    |> Selectors.text()
    |> Enum.find(fn element -> element |> String.contains?("Price:") end)
    |> Price.new()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Selectors.all_matches(css(".event-meta"))
    |> Selectors.text()
    |> Enum.find(fn element -> element |> String.contains?("Ages:") end)
    |> String.split("|")
    |> Enum.at(1)
    |> String.split(":")
    |> Enum.at(1)
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".event-ticket-link"))
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
