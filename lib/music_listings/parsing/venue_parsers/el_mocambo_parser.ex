defmodule MusicListings.Parsing.VenueParsers.ElMocamboParser do
  @moduledoc """
  Parser for extracing events from https://elmocambo.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://elmocambo.com/events-new"

  @impl true
  def example_data_file_location, do: "test/data/el_mocambo/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".stratum-advanced-posts__post"))
    |> Enum.filter(fn article ->
      Selectors.match_one(article, css("span.stratum-advanced-posts__post-date")) != nil
    end)
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
  def ignored_event_id(event) do
    Selectors.attr(event, "id")
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".stratum-advanced-posts__post-title a"))
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
      |> Selectors.text(css(".stratum-advanced-posts__post-date"))
      |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
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
    Selectors.url(event, css(".stratum-advanced-posts__read-more a"))
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".stratum-advanced-posts__post-link"))
  end
end
