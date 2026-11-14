defmodule MusicListings.Parsing.VenueParsers.MonarchTavernParser do
  @moduledoc """
  Parser for extracting events from https://www.themonarchtavern.com/events

  The site is a React app whose events page is filled in by JavaScript from the
  venue's Supabase project.  This parser reads the same table the page does, through
  Supabase's REST API, using the public `anon` key shipped in the site's JavaScript
  bundle (it's meant to be public: every visitor's browser sends it), i.e.

      [%{"id" => "5b830084-71fe-4857-b147-41a1efb5578c",
         "slug" => "dabda-2026-11-21",
         "title" => "Dabda",
         "start_at" => "2026-11-22T01:00:00+00:00",
         "venue" => "downstairs",
         "ticket_url" => "https://dice.fm/event/6aa42b646b03960001547a69",
         "description" => "...", ...}]

  Only the `downstairs` room is listed - it's where the bands play.  Upstairs is the
  bar's DJ, karaoke and sports nights.  The venue's Tockify calendar, which this
  parser used to read, now only has those upstairs nights.

  If the venue rotates the key, the new one is in the site's JS bundle (look for
  `supabase.co`).
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @venue_name "monarch_tavern"
  @site_url "https://www.themonarchtavern.com"
  @events_url "https://ffejqqqltnseiytktcmy.supabase.co/rest/v1/events"
  @anon_key "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmZWpxcXFsdG5zZWl5dGt0Y215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0NjU5NjUsImV4cCI6MjA5NjA0MTk2NX0.kVa5bmccbhkwgH5gO1WHCsnUsbaYbRtCmRnQIJY6JgQ"
  @fields "id,slug,title,start_at,venue,description,ticket_url,status"
  @room "downstairs"

  # Some listings append the venue to the bands, e.g. "Cherry Garcia Band, Tell It
  # To Sweeney at the Monarch Tavern"
  @at_the_monarch ~r/\s+at\s+(the\s+)?monarch(\s+tavern)?\s*$/i

  @impl true
  def source_url do
    query =
      URI.encode_query(%{
        "select" => @fields,
        "venue" => "eq.#{@room}",
        "status" => "eq.published",
        "start_at" => "gte.#{DateHelpers.today()}",
        "order" => "start_at.asc"
      })

    "#{@events_url}?#{query}"
  end

  @impl true
  def retrieve_events_fun do
    fn url ->
      HttpClient.get(url, [
        {"apikey", @anon_key},
        {"authorization", "Bearer #{@anon_key}"},
        {"accept", "application/json"}
      ])
    end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Enum.filter(&listed?/1)
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  # Every occurrence of a recurring show is its own row, with its own id
  @impl true
  def event_id(event), do: "#{@venue_name}_#{event["id"]}"

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event["title"]
    |> String.replace(@at_the_monarch, "")
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event |> start_at() |> DateHelpers.to_eastern_date()

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event |> start_at() |> DateHelpers.to_eastern_time()

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(event) do
    description = event["description"] || ""

    cond do
      description =~ ~r/\b19\+/ -> :nineteen_plus
      description =~ ~r/\ball[\s-]ages\b/i -> :all_ages
      true -> :unknown
    end
  end

  @impl true
  def ticket_url(event), do: event["ticket_url"]

  @impl true
  def details_url(event), do: "#{@site_url}/events/#{event["slug"]}"

  # The venue's admin saves some placeholder listings with a blank title, or "@"
  defp listed?(event), do: event["venue"] == @room and event["title"] =~ ~r/[[:alnum:]]/u

  defp start_at(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["start_at"])
    datetime
  end
end
