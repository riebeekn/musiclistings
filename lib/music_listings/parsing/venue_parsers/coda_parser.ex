defmodule MusicListings.Parsing.VenueParsers.CodaParser do
  @moduledoc """
  Parser for extracing events from https://codatoronto.com/

  Note: Coda migrated from Webflow to WordPress/Elementor in late 2024.
  The new site structure only displays dates for some events. This parser
  filters to only return events that have dates displayed.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://codatoronto.com/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".e-loop-item.type-events"))
    |> Enum.filter(&has_date?/1)
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)

    ParseHelpers.build_id_from_venue_and_date("coda", date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    headings = Selectors.all_matches(event, css(".elementor-heading-title"))

    # Second heading is the title (first is the date)
    headings
    |> Enum.at(1)
    |> Selectors.text()
  end

  @impl true
  def performers(event) do
    event
    |> event_title()
    |> List.wrap()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    headings = Selectors.all_matches(event, css(".elementor-heading-title"))

    # First heading contains the date in format like "Saturday, April 25"
    headings
    |> Enum.at(0)
    |> Selectors.text()
    |> ParseHelpers.parse_day_month_day_string()
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
    Selectors.url(event, css("a.elementor-button[href*='ticketweb']"))
  end

  @impl true
  def details_url(event) do
    ticket_url(event)
  end

  # Private helpers

  defp has_date?(event) do
    headings = Selectors.all_matches(event, css(".elementor-heading-title"))

    # Events with dates have 2 headings: date and title
    # Events without dates have only 1 heading: title
    if length(headings) >= 2 do
      first_heading = headings |> Enum.at(0) |> Selectors.text()
      date_string?(first_heading)
    else
      false
    end
  end

  defp date_string?(text) do
    # Match patterns like "Saturday, April 25" or "Friday, May 22"
    Regex.match?(
      ~r/^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}$/i,
      String.trim(text)
    )
  end
end
