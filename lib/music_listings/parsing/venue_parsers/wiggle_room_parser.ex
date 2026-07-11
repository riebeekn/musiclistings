defmodule MusicListings.Parsing.VenueParsers.WiggleRoomParser do
  @moduledoc """
  Parser for extracting events from https://wiggleroomtoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WordpressParser

  @impl true
  def source_url, do: "https://wiggleroomtoronto.com/events/"

  @impl true
  defdelegate retrieve_events_fun, to: WordpressParser

  @impl true
  # Wiggle Room's page has multiple ld+json scripts (Yoast SEO graph comes
  # first, The Events Calendar's event list second), so we can't use the base
  # parser's match_one - select the script that decodes to a list of events.
  def events(body) do
    body
    |> Selectors.all_matches(css(~s(script[type="application/ld+json"])))
    |> Enum.map(fn script -> script |> Selectors.data() |> Jason.decode!() end)
    |> Enum.find([], &is_list/1)
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: WordpressParser

  @impl true
  def event_id(event) do
    WordpressParser.event_id(event, "wiggle_room")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: WordpressParser

  @impl true
  defdelegate performers(event), to: WordpressParser

  @impl true
  defdelegate event_date(event), to: WordpressParser

  @impl true
  defdelegate additional_dates(event), to: WordpressParser

  @impl true
  defdelegate event_time(event), to: WordpressParser

  @impl true
  defdelegate price(event), to: WordpressParser

  @impl true
  defdelegate age_restriction(event), to: WordpressParser

  @impl true
  defdelegate ticket_url(event), to: WordpressParser

  @impl true
  defdelegate details_url(event), to: WordpressParser
end
