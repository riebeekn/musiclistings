defmodule MusicListings.Parsing.VenueParsers.CameronHouseParser do
  @moduledoc """
  Parser for extracing events from https://www.thecameron.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.thecameron.com/shows"

  @impl true
  def example_data_file_location, do: "test/data/cameron_house/index.html"

  @impl true
  def events(body) do
    json =
      body
      |> Selectors.match_one(css("script[type=\"application/json\"]#wix-warmup-data"))
      |> Selectors.data()
      |> Jason.decode!()

    json["appsWarmupData"]["140603ad-af8d-84a5-2c80-a0f60cb47351"]["widgetcomp-j9ny0yyr"][
      "events"
    ]["events"]
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event["id"]
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    {:ok, utc_datetime, _offset} =
      event["scheduling"]["config"]["startDate"]
      |> DateTime.from_iso8601()

    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
    |> DateTime.to_date()
  end

  @impl true
  def event_time(event) do
    {:ok, utc_datetime, _offset} =
      event["scheduling"]["config"]["startDate"]
      |> DateTime.from_iso8601()

    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
    |> DateTime.truncate(:second)
    |> DateTime.to_time()
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
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
