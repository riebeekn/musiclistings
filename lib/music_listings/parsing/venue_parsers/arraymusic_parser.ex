defmodule MusicListings.Parsing.VenueParsers.ArraymusicParser do
  @moduledoc """
  Parser for extracing events from https://www.arraymusic.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParser

  # Update each season, when Array posts the new season at a glance page
  @season_start_year 2026

  @impl true
  def source_url do
    season = "#{rem(@season_start_year, 100)}-#{rem(@season_start_year + 1, 100)}"
    "https://www.arraymusic.ca/#{season}-season-at-a-glance/"
  end

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".sp-pcp-post-details-content"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
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
    Selectors.text(event, css(".sp-pcp-title"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    parse_dates(event).date
  end

  @impl true
  def additional_dates(event) do
    parse_dates(event).additional_dates
  end

  defp parse_dates(event) do
    event
    |> date_time_string()
    |> DateParser.parse_dates(@season_start_year)
  end

  @impl true
  def event_time(event) do
    event
    |> date_time_string()
    |> DateParser.parse_time()
  end

  defp date_time_string(event) do
    Selectors.text(event, css(".sp_pcp_ctf-event_date_time"))
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
    Selectors.url(event, css(".sp-pcp-title a"))
  end
end
