defmodule MusicListings.Parsing.VenueParsers.PilotParser do
  @moduledoc """
  Parser for extracing events from https://thepilot.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.thepilot.ca/happening-at-the-pilot"

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
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
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

    [_day_of_week, month_string, day_string] = String.split(full_date_string)

    ParseHelpers.build_date_from_month_day_strings(month_string, day_string, Date.utc_today())
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
    nil
  end
end
