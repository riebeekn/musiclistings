defmodule MusicListings.Parsing.VenueParsers.BaseParsers.TockifyParser do
  @moduledoc """
  Base parser for Tockify calendar sites
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @doc """
  Builds the Tockify API URL for a given calendar name.
  """
  def build_source_url(calendar_name) do
    unix_today_in_milliseconds =
      (DateHelpers.today() |> DateTime.new!(~T[00:00:00]) |> DateTime.to_unix()) * 1_000

    "https://tockify.com/api/ngevent?max=48&view=agenda&calname=#{calendar_name}&start-inclusive=true&longForm=false&showAll=false&startms=#{unix_today_in_milliseconds}"
  end

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id_from_date(venue_name, event) do
    date = event_date(event)

    ParseHelpers.build_id_from_venue_and_date(venue_name, date)
  end

  def event_id_from_datetime(venue_name, event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime(venue_name, date, time)
  end

  def event_title(event) do
    event["content"]["summary"]["text"]
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event["when"]["start"]["millis"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_date()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event["when"]["start"]["millis"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_datetime()
    |> DateTime.to_time()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event["content"]["customButtonLink"]
  end

  def details_url(_event) do
    nil
  end
end
