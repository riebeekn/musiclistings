defmodule MusicListings.Parsing.VenueParsers.TimothysPubParser do
  @moduledoc """
  Parser for extracting events from https://www.timothyspub.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url do
    unix_today_in_milliseconds =
      (DateHelpers.today() |> DateTime.new!(~T[00:00:00]) |> DateTime.to_unix()) * 1_000

    "https://tockify.com/api/ngevent?max=48&view=agenda&calname=robinbrem&start-inclusive=true&longForm=false&showAll=false&startms=#{unix_today_in_milliseconds}"
  end

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/timothys_pub/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
    |> Enum.filter(&has_live_music_tag?/1)
  end

  defp has_live_music_tag?(event) do
    tags = get_in(event, ["content", "tagset", "tags", "default"]) || []
    "LIVE-@-TIMOTHY'S-PUB" in tags
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)

    ParseHelpers.build_id_from_venue_and_date("timothys_pub", date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["content"]["summary"]["text"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["when"]["start"]["millis"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_date()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    event["content"]["customButtonLink"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
