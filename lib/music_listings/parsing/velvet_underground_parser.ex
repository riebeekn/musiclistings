defmodule MusicListings.Parsing.VelvetUndergroundParser do
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser

  @impl true
  def source_url, do: "https://thevelvet.ca/events/"

  @impl true
  def venue_name, do: "Velvet Underground"

  @impl true
  def event_selector(body) do
    Parser.event_selector(body, ".event-block")
  end

  @impl true
  def next_page_url(body) do
    Parser.next_page_url(body, ".nav-previous a")
  end

  @impl true
  def event_id(event) do
    Parser.event_id(event, ".event-block")
  end

  @impl true
  def event_title(event) do
    Parser.event_title(event, ".event-title")
  end

  @impl true
  def performers(event) do
    Parser.performers(event, ".event-artist-name")
  end

  @impl true
  def event_date(event) do
    date_string =
      event
      |> Meeseeks.one(css(".event-block"))
      |> Meeseeks.Result.attr("data-event-date")

    year = date_string |> String.slice(0..3) |> String.to_integer()
    month = date_string |> String.slice(4..5) |> String.to_integer()
    day = date_string |> String.slice(6..7) |> String.to_integer()

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(0)
    |> String.split(" ")
    |> Enum.at(1)
    |> Parser.convert_event_time_string_to_time()
  end

  @impl true
  def price(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Price:") end)
    |> Meeseeks.text()
    |> Parser.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(1)
    |> String.split(":")
    |> Enum.at(1)
    |> Parser.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Parser.ticket_url(event, ".event-ticket-link")
  end
end
