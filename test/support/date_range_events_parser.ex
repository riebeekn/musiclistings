defmodule MusicListings.Parsing.VenueParsers.DateRangeEventsParser do
  @moduledoc """
  Test parser returning one event well inside the crawl window, one far enough
  in the future to look like a mis-inferred year, and one in the past.  Used to
  test the date filtering the crawler applies before storing events.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url, do: "https://example.com/events"

  @impl true
  def retrieve_events_fun do
    fn _url -> {:ok, %MusicListings.HttpClient.Response{status: 200, body: "{}"}} end
  end

  @impl true
  def events(_body) do
    today = DateHelpers.now() |> DateHelpers.to_eastern_date()

    [
      %{"id" => "upcoming", "date" => Date.add(today, 30)},
      %{"id" => "far_future", "date" => Date.add(today, 551)},
      %{"id" => "past", "date" => Date.add(today, -30)}
    ]
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

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
