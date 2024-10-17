defmodule MusicListings.Parsing.VenueParsers.ConcertHallParser do
  @moduledoc """
  Parser for extracing events from https://888yonge.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://888yonge.com"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/concert_hall/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> Enum.map(&(&1 |> ParseHelpers.strip_extra_quotes() |> Jason.decode!()))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
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
    |> ParseHelpers.add_seconds_and_offset_to_datetime_string()
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
    |> ParseHelpers.add_seconds_and_offset_to_datetime_string()
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
  def ticket_url(event) do
    event["offers"]["url"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
