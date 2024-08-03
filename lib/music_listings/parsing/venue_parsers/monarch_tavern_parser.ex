defmodule MusicListings.Parsing.VenueParsers.MonarchTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.themonarchtavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url do
    unix_today_in_milliseconds =
      (Date.utc_today() |> DateTime.new!(~T[00:00:00]) |> DateTime.to_unix()) * 1_000

    "https://tockify.com/api/ngevent?max=48&view=agenda&calname=monarchtavern&start-inclusive=true&longForm=false&showAll=false&startms=#{unix_today_in_milliseconds}"
  end

  @impl true
  def example_data_file_location, do: "test/data/monarch_tavern/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
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
    |> DateTime.to_date()
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
