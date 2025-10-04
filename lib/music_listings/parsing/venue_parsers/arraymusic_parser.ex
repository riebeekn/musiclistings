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

  @impl true
  def source_url, do: "https://www.arraymusic.ca/current-season/25-26-season-at-a-glance/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/arraymusic/index.html"

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
    date_string = Selectors.text(event, css(".sp_pcp_ctf-event_date_time"))

    parsed_dates =
      event
      |> event_title()
      |> DateParser.parse_dates(date_string)

    parsed_dates.date
  end

  @impl true
  def additional_dates(event) do
    date_string = Selectors.text(event, css(".sp_pcp_ctf-event_date_time"))

    parsed_dates =
      event
      |> event_title()
      |> DateParser.parse_dates(date_string)

    parsed_dates.additional_dates
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
    Selectors.url(event, css(".sp-pcp-title a"))
  end
end
