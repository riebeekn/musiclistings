defmodule MusicListings.Parsing.VenueParsers.CastrosLoungeParser do
  @moduledoc """
  Parser for extracing events from https://castroslounge.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://castroslounge.com/events/month/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/castros_lounge/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.match_one(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> Jason.decode!()
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("castros_lounge", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["name"]
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event["name"]]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
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
    event["url"]
  end
end
