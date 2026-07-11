defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ResidentAdvisorParser do
  @moduledoc """
  Base parser for venues listed on Resident Advisor (ra.co).

  RA club pages (`ra.co/clubs/<club_id>`) are server-rendered Next.js pages that
  embed their data in a `#__NEXT_DATA__` script as an Apollo cache. Venue parsers
  construct their `source_url` via `build_source_url/1` and delegate the rest of
  the `VenueParser` callbacks here, passing their RA club id so we can scope the
  events to that venue.

  The Apollo cache holds both the venue's upcoming events (which carry a
  `venue` ref back to the club) and unrelated past events (whose `venue` is
  `null`), so we filter to events pointing at this club.
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://ra.co"

  # RA is behind Cloudflare, which 403s requests that don't look like a browser.
  # A User-Agent alone isn't enough - the full set of navigation headers below is
  # required to get a 200. (accept-encoding is deliberately omitted so the HTTP
  # client manages compression itself and decodes the response correctly.)
  @browser_headers [
    {"user-agent",
     "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"},
    {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
    {"accept-language", "en-US,en;q=0.9"},
    {"sec-fetch-dest", "document"},
    {"sec-fetch-mode", "navigate"},
    {"sec-fetch-site", "none"},
    {"upgrade-insecure-requests", "1"}
  ]

  def build_source_url(club_id), do: "#{@base_url}/clubs/#{club_id}"

  def retrieve_events_fun do
    fn url -> HttpClient.get(url, @browser_headers) end
  end

  def events(body, club_id) do
    venue_ref = "Venue:#{club_id}"

    body
    |> apollo_state()
    |> Map.values()
    |> Enum.filter(fn value ->
      is_map(value) and value["__typename"] == "Event" and
        get_in(value, ["venue", "__ref"]) == venue_ref
    end)
  end

  def next_page_url(_body, _current_url), do: nil

  def event_id(event, venue_id_prefix), do: "#{venue_id_prefix}_#{event["id"]}"

  def event_title(event), do: event["title"]

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event["date"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  def additional_dates(_event), do: []

  def event_time(event) do
    case event["startTime"] do
      nil ->
        nil

      start_time ->
        start_time
        |> NaiveDateTime.from_iso8601!()
        |> NaiveDateTime.to_time()
    end
  end

  def price(_event), do: Price.unknown()

  def age_restriction(_event), do: :unknown

  def ticket_url(_event), do: nil

  def details_url(event), do: "#{@base_url}#{event["contentUrl"]}"

  defp apollo_state(body) do
    body
    |> Selectors.match_one(css("script#__NEXT_DATA__"))
    |> Selectors.data()
    |> Jason.decode!()
    |> get_in(["props", "apolloState"])
    |> case do
      nil -> %{}
      apollo_state -> apollo_state
    end
  end
end
