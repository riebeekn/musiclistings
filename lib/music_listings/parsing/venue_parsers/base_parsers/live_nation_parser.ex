defmodule MusicListings.Parsing.VenueParsers.BaseParsers.LiveNationParser do
  @moduledoc """
  Base parser for Live Nation sites
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    body
    |> Selectors.all_matches(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> Enum.map(&Jason.decode!/1)
    |> Enum.filter(&(&1["@type"] == "MusicEvent"))
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event, venue_name) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime(venue_name, date, time)
  end

  def event_title(event) do
    event["name"]
  end

  def performers(event) do
    event["performers"]
    |> Enum.map(& &1["name"])
    |> Performers.new()
  end

  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event["url"]
  end

  def details_url(_event) do
    nil
  end
end
