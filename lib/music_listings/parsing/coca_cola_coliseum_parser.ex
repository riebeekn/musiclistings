defmodule MusicListings.Parsing.CocaColaColiseumParser do
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
    regex = ~r/event\/(?<event_id>[^?\/]+)(?:\?|$)/
    ticket_url = ticket_url(event)
    Regex.named_captures(regex, ticket_url)["event_id"]
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
    day_string =
      event
      |> Meeseeks.one(css(".m-date__day"))
      |> Meeseeks.Result.text()
      |> String.trim()

    month_string =
      event
      |> Meeseeks.one(css(".m-date__month"))
      |> Meeseeks.Result.text()
      |> String.trim()

    year_string =
      event
      |> Meeseeks.one(css(".m-date__year"))
      |> Meeseeks.Result.text()
      |> String.replace(",", "")
      |> String.trim()

    day = String.to_integer(day_string)
    month = Parser.convert_month_string_to_number(month_string)
    year = String.to_integer(year_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.one(css(".m-eventItem__start"))
    |> Meeseeks.Result.text()
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
