defmodule MusicListings.Parsing.VenueParsers.ScotiabankParser do
  @moduledoc """
  Parser for extracing events from https://www.scotiabankarena.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url,
    do:
      "https://www.scotiabankarena.com/events/events_ajax/9?category=1&venue=0&team=0&exclude=&per_page=63&came_from_page=event-list-page"

  @impl true
  def example_data_file_location, do: "test/data/scotiabank/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".eventItem"))
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
    Selectors.text(event, css(".info .title a"))
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
    month = ParseHelpers.convert_month_string_to_number(month_string)
    year = year_string |> String.replace(",", "") |> String.trim() |> String.to_integer()

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(_event) do
    Price.new(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".more"))
  end
end
