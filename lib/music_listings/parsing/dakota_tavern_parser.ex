defmodule MusicListings.Parsing.DakotaTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.dakotatavern.ca/
  """
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url, do: "https://www.dakotatavern.ca"

  @impl true
  def venue_name, do: "The Dakota Tavern"

  @impl true
  def example_data_file_location, do: "test/data/dakota_tavern/index.html"

  @impl true
  def event_selector(body) do
    Parser.event_selector(body, ".grid-item")
  end

  @impl true
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    # TODO: common
    slug = "#{event_title(event)}-#{event_date(event)}"
    # TODO: should also probably downcase this
    Regex.replace(~r/[[:punct:]\s]+/, slug, "_")
  end

  @impl true
  def event_title(event) do
    [_date, title] =
      event
      |> Parser.event_title(".portfolio-title")
      |> String.split("-")

    title |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [date, _title] =
      event
      |> Parser.event_title(".portfolio-title")
      |> String.split("-")

    [_day_of_week, month_and_day_string, year_string] = String.split(date, ",")

    [month_string, day_string] = month_and_day_string |> String.split()

    year = year_string |> String.trim() |> String.to_integer()
    month = month_string |> Parser.convert_month_string_to_number()
    day = day_string |> String.to_integer()

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(_event) do
    nil
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
    event_url =
      event
      |> Meeseeks.one(css(".grid-item"))
      |> Meeseeks.attr("href")

    "#{source_url()}#{event_url}"
  end
end
