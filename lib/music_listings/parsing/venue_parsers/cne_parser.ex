defmodule MusicListings.Parsing.VenueParsers.CneParser do
  @moduledoc """
  Parser for extracing events from https://www.theex.com/performances/music/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url,
    do:
      "https://www.theex.com/wp-json/cne/v1/performers?locations=beach-bar-stage,bell-cne-bandshell,casino-patio,country-stage,midway-stage,wine-garden"

  @impl true
  def retrieve_events_fun do
    fn url -> Req.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/cne/index.json"

  @impl true
  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    event["id"]
    |> Integer.to_string()
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [month, day, year] =
      event["dates"]
      |> List.first()
      |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
  end

  @impl true
  def additional_dates(event) do
    [_first_date | remaining_dates] = event["dates"]

    Enum.map(remaining_dates, fn date_string ->
      [month, day, year] = String.split(date_string)
      ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
    end)
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
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(event) do
    "https://www.theex.com/performances/music/##{event["slug"]}"
  end
end
