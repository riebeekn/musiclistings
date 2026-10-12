defmodule MusicListings.Parsing.VenueParsers.DuplicateListingParser do
  @moduledoc """
  Test parser whose second page lists one of the first page's events again,
  as a paged listing does when its order shifts between requests.  Each event
  that is parsed reports a lookup failure, so the crawl report shows how many
  were parsed.  Used to test that `dedupe_key/1` parses the repeat only once.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.LookupFailures
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url, do: "https://example.com/events?page=1"

  @impl true
  def retrieve_events_fun do
    fn url -> {:ok, %Response{status: 200, body: url}} end
  end

  @impl true
  def events("https://example.com/events?page=1"), do: ["first", "repeated"]
  def events("https://example.com/events?page=2"), do: ["repeated", "last"]

  @impl true
  def next_page_url("https://example.com/events?page=1", _current_url),
    do: "https://example.com/events?page=2"

  def next_page_url(_body, _current_url), do: nil

  @impl true
  def dedupe_key(event), do: event

  @impl true
  def event_id(event), do: event

  @impl true
  def ignored_event_id(event), do: event

  @impl true
  def event_title(event), do: event

  @impl true
  def performers(event), do: Performers.new([event])

  @impl true
  def event_date(_event), do: DateHelpers.now() |> DateHelpers.to_eastern_date() |> Date.add(30)

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(_event), do: nil

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event) do
    LookupFailures.record([:ticket_url], "lookup for #{event}")
    nil
  end

  @impl true
  def details_url(_event), do: nil
end
