defmodule MusicListings.Parsing.VenueParsers.HandlebarParser do
  @moduledoc """
  Parser for extracing events from https://thehandlebar.ca/
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
      "https://calendar.apps.secureserver.net/v1/events/366947a0-303a-47c1-b561-5117b38b90ad/73550132-2f76-4daf-bb5b-1a9eff16e360/b0095722-7dba-4b95-8d4a-a1913fcbbe34"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/handlebar/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("handlebar", date, time)
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
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["start"])
    DateHelpers.to_eastern_date(datetime)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["start"])
    DateHelpers.to_eastern_time(datetime)
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
  def details_url(_event) do
    "https://thehandlebar.ca/"
  end
end
