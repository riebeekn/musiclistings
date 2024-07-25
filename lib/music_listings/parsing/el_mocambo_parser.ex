defmodule MusicListings.Parsing.ElMocamboParser do
  @moduledoc """
  Parser for extracing events from https://elmocambo.com/
  """
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url, do: "https://elmocambo.com/events-new"

  @impl true
  def venue_name, do: "El Mocambo"

  @impl true
  def example_data_file_location, do: "test/data/el_mocambo/index.html"

  @impl true
  def event_selector(body) do
    body
    |> Meeseeks.all(css(".stratum-advanced-posts__post"))
    |> Enum.filter(fn article ->
      Meeseeks.one(article, css("span.stratum-advanced-posts__post-date")) != nil
    end)
  end

  @impl true
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    title_slug = event |> event_title() |> String.replace(" ", "")
    "#{title_slug}-#{event_date(event)}"
  end

  @impl true
  def event_title(event) do
    Parser.event_title(event, ".stratum-advanced-posts__post-title a")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [month_string, day_string, year_string] =
      event
      |> Meeseeks.one(css(".stratum-advanced-posts__post-date"))
      |> Meeseeks.text()
      |> String.split()

    day = day_string |> String.replace(",", "") |> String.to_integer()
    month = Parser.convert_month_string_to_number(month_string)
    year = String.to_integer(year_string)

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
    Parser.ticket_url(event, ".stratum-advanced-posts__read-more a")
  end
end
