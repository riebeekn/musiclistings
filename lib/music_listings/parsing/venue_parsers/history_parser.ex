defmodule MusicListings.Parsing.VenueParsers.HistoryParser do
  @moduledoc """
  Parser for extracing events from https://www.historytoronto.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers

  @impl true
  def source_url, do: "https://www.historytoronto.com/events/events_ajax/0?per_page=60"

  @impl true
  def example_data_file_location, do: "test/data/history/index.html"

  @impl true
  def events(body) do
    ParseHelpers.event_selector(body, ".eventItem")
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event
    |> ticket_url()
    |> ParseHelpers.extract_event_id_from_ticketmaster_url()
  end

  @impl true
  def event_title(event) do
    ParseHelpers.event_title(event, ".title")
  end

  @impl true
  def performers(event) do
    ParseHelpers.performers(event, ".title")
  end

  @impl true
  def event_date(event) do
    ParseHelpers.extract_date_from_m__xx_format(event)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.one(css(".start"))
    |> Meeseeks.text()
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(_event) do
    ParseHelpers.convert_price_string_to_price(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    ParseHelpers.ticket_url(event, ".tickets")
  end
end
