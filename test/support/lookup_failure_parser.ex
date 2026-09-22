defmodule MusicListings.Parsing.VenueParsers.LookupFailureParser do
  @moduledoc """
  Test parser whose single event's ticket link lookup always fails, as a
  follow-up request blocked by Cloudflare would.  Used to test that the crawl
  reports the failure and keeps any ticket link already stored.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.LookupFailures
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url, do: "https://example.com/events"

  @impl true
  def retrieve_events_fun do
    fn _url -> {:ok, %Response{status: 200, body: "{}"}} end
  end

  @impl true
  def events(_body), do: ["blocked_event"]

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: event

  @impl true
  def ignored_event_id(event), do: event

  @impl true
  def event_title(_event), do: "Blocked Show"

  @impl true
  def performers(_event), do: Performers.new(["Blocked Show"])

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
  def ticket_url(_event) do
    LookupFailures.record([:ticket_url], "HTTP 403 from https://example.com/tickets")
    nil
  end

  @impl true
  def details_url(_event), do: nil
end
