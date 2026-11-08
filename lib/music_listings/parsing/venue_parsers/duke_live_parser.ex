defmodule MusicListings.Parsing.VenueParsers.DukeLiveParser do
  @moduledoc """
  Parser for extracting events from https://dukelive.ca/

  The site's events page is rendered from its own JSON endpoint, `/api/events`, which
  proxies the venue's Eventbrite listings, i.e.

      %{"events" => [%{"id" => "2004429790461",
                        "name" => %{"text" => "Megacity Big Band Presented by The Duke Live"},
                        "url" => "https://www.eventbrite.ca/e/...",
                        "start" => %{"local" => "2026-11-08T17:00:00"},
                        "is_free" => false, ...}]}

  The endpoint returns every upcoming event in one response.  Each occurrence of a
  recurring event is its own Eventbrite event with its own id, so the id is used as is.

  Karaoke nights are skipped, and the "Presented by The Duke Live" the venue tacks on
  to most titles is removed.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @skipped_title ~r/karaoke/i
  # "Presented by The Duke Live", "Presented By The Duke Live", "Presented by: The Duke Live"
  @presented_by ~r/\s*\bpresented\s+by:?\s+the\s+duke\s+live\b\s*/i

  @impl true
  def source_url, do: "https://dukelive.ca/api/events"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url, [{"accept", "application/json"}]) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("events", [])
    |> Enum.reject(&(get_in(&1, ["name", "text"]) =~ @skipped_title))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: "duke_live_#{event["id"]}"

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event
    |> get_in(["name", "text"])
    |> String.replace(@presented_by, " ")
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event |> start_datetime() |> NaiveDateTime.to_date()

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event |> start_datetime() |> NaiveDateTime.to_time()

  @impl true
  def price(%{"is_free" => true}), do: Price.new("free")
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event), do: event["url"]

  @impl true
  def details_url(event), do: event["url"]

  # Eventbrite's local start time is Toronto's wall clock time
  defp start_datetime(event) do
    event
    |> get_in(["start", "local"])
    |> NaiveDateTime.from_iso8601!()
  end
end
