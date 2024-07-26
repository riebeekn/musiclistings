defmodule MusicListings.Parsing.VenueParsers.CocaColaColiseumParser do
  @moduledoc """
  Parser for extracing events from https://www.coca-colacoliseum.com/
  """
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser

  @impl true
  def source_url, do: "https://www.coca-colacoliseum.com/events"

  @impl true
  def venue_name, do: "Coca Cola Coliseum"

  @impl true
  def example_data_file_location, do: "test/data/coca_cola_coliseum/index.html"

  @impl true
  def event_selector(body) do
    Parser.event_selector(body, ".m-venueframework-eventslist__item")
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
    |> Parser.extract_event_id_from_ticketmaster_url()
  end

  @impl true
  def event_title(event) do
    Parser.event_title(event, ".m-eventItem__title")
  end

  @impl true
  def performers(event) do
    Parser.performers(event, ".m-eventItem__title")
  end

  @impl true
  def event_date(event) do
    Parser.extract_date_from_m__xx_format(event)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.one(css(".m-eventItem__start"))
    |> Meeseeks.text()
    |> Parser.convert_event_time_string_to_time()
  end

  @impl true
  def price(_event) do
    Parser.convert_price_string_to_price(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    Parser.ticket_url(event, ".tickets")
  end
end
