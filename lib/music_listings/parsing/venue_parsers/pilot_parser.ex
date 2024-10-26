defmodule MusicListings.Parsing.VenueParsers.PilotParser do
  @moduledoc """
  Parser for extracing events from https://thepilot.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.thepilot.ca/happening-at-the-pilot"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/pilot/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(
      body,
      css("div#scvr-section-013c83e7-396f-4090-a781-83f7097a960c p.fr-tag")
    )
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)

    ParseHelpers.build_id_from_venue_and_date("pilot", date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".fr-tag strong, .fr-tag b"))
    |> String.replace(".", "")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [full_date_string | _rest] =
      event
      |> Selectors.text(css(".fr-tag"))
      |> String.split("-")

    [_day_of_week, month_string, day_string] =
      full_date_string |> String.replace(",", " ") |> String.split()

    ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
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
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(_event) do
    "https://www.thepilot.ca/happening-at-the-pilot"
  end
end
