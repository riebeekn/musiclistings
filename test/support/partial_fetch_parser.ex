defmodule MusicListings.Parsing.VenueParsers.PartialFetchParser do
  @moduledoc """
  Test parser whose first page returns an upcoming event and whose second page
  fails with a 403.  Used to test that a fetch failure on a later page is
  reported without discarding the events already retrieved.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url, do: "https://example.com/events"

  @impl true
  def retrieve_events_fun do
    fn
      "https://example.com/events" -> {:ok, %Response{status: 200, body: "page 1"}}
      _url -> {:ok, %Response{status: 403, body: "Forbidden"}}
    end
  end

  @impl true
  def events(_body) do
    today = DateHelpers.now() |> DateHelpers.to_eastern_date()
    [%{"id" => "page_1_event", "date" => Date.add(today, 30)}]
  end

  @impl true
  def next_page_url("page 1", _current_url), do: "https://example.com/events?page=2"

  @impl true
  def event_id(event), do: event["id"]

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["id"]

  @impl true
  def performers(_event), do: Performers.new([])

  @impl true
  def event_date(event), do: event["date"]

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
