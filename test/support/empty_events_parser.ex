defmodule MusicListings.Parsing.VenueParsers.EmptyEventsParser do
  @moduledoc """
  Test parser that returns no events, used for testing no_events_error
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url, do: "https://example.com/events"

  @impl true
  def retrieve_events_fun do
    fn _url -> {:ok, %MusicListings.HttpClient.Response{status: 200, body: "{}"}} end
  end

  @impl true
  def example_data_file_location, do: "test/data/empty_events/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)
    body["data"]["getEvents"]
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: event["discovery_id"]

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["name"]

  @impl true
  def performers(_event), do: Performers.new([])

  @impl true
  def event_date(event), do: Date.from_iso8601!(event["event_date"])

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(_event), do: nil

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: nil
end
