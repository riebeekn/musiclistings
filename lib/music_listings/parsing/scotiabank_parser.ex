defmodule MusicListings.Parsing.ScotiabankParser do
  @moduledoc """
  Parser for extracing events from https://www.scotiabankarena.com
  """
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url,
    do:
      "https://www.scotiabankarena.com/events/events_ajax/9?category=1&venue=0&team=0&exclude=&per_page=63&came_from_page=event-list-page"

  @impl true
  def venue_name, do: "Scotiabank Arena"

  @impl true
  def example_data_file_location, do: "test/data/scotiabank/index.html"

  @impl true
  def event_selector(body) do
    Parser.event_selector(body, ".eventItem")
  end

  @impl true
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    # TODO: common
    slug = "#{event_title(event)}-#{event_date(event)}"

    ~r/[[:punct:]\s]+/
    |> Regex.replace(slug, "_")
    |> String.downcase()
  end

  @impl true
  def event_title(event) do
    Parser.event_title(event, ".info .title a")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    day_string = event |> Meeseeks.one(css(".m-date__day")) |> Meeseeks.text()
    month_string = event |> Meeseeks.one(css(".m-date__month")) |> Meeseeks.text()
    year_string = event |> Meeseeks.one(css(".m-date__year")) |> Meeseeks.text()

    day = String.to_integer(day_string)
    month = Parser.convert_month_string_to_number(month_string)
    year = year_string |> String.replace(",", "") |> String.trim() |> String.to_integer()

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
    Parser.ticket_url(event, ".more")
  end
end