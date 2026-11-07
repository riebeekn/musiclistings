defmodule MusicListings.Parsing.VenueParsers.BerczyTavernParser do
  @moduledoc """
  Parser for extracting events from https://www.theberczy.com/piano-bar

  The site is on Next.js and server renders the current month's live piano
  schedule twice: as a calendar grid for desktop and as a list of articles for
  mobile.  We parse the list, which has one article per set.  Sets don't have an
  id and a day can have two of them (brunch and evening on a Saturday), so the id
  is built from the date and time.  The page states there is no cover charge.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://www.theberczy.com/piano-bar"

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css("#live-piano-schedule article"))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_datetime(
      "berczy_tavern",
      event_date(event),
      event_time(event)
    )
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    Selectors.text(event, css("h3"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> Selectors.match_one(css("time"))
    |> Selectors.attr("datetime")
    |> Date.from_iso8601!()
  end

  @impl true
  def additional_dates(_event), do: []

  # i.e. "7:00pm – 10:30pm"
  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css("span"))
    |> String.split("–")
    |> List.first()
    |> ParseHelpers.time_from_time_string()
  end

  @impl true
  def price(_event), do: Price.new("free")

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: "#{@source_url}#live-piano-schedule"
end
