defmodule MusicListings.Parsing.VenueParsers.BurdockParser do
  @moduledoc """
  Parser for extracing events from https://burdockbrewery.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url,
    do:
      "https://broker.eventscalendar.co/api/eventbrite/next?count=20&from=1736586000000&project=proj_T8vacNv8cWWeEQAQwLKHb&calendar=103809367271"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/burdock/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    event["id"]
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    {:ok, utc_datetime, _offset} =
      event["start_time"]
      |> DateTime.from_iso8601()

    DateHelpers.to_eastern_date(utc_datetime)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(_event) do
    nil
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
    event["tickets_link"]
  end

  @impl true
  def details_url(event) do
    event["event_link"]
  end
end
