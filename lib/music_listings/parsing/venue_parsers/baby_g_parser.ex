defmodule MusicListings.Parsing.VenueParsers.BabyGParser do
  @moduledoc """
  Parser for extracing events from http://thebabyg.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "http://thebabyg.com"

  @impl true
  def example_data_file_location, do: "test/data/baby_g/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css("#calendar_wrap"))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
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
    Selectors.text(event, css("#calendar_info_headliner"))
  end

  @impl true
  def performers(event) do
    openers =
      event
      |> Selectors.text(css("#calendar_info_support a"))

    headliner = event_title(event)

    ([headliner] ++ [openers])
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week, month_string, day_string] =
      event
      |> Selectors.text(css("#calendar_date"))
      |> String.split()

    ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
  end

  @impl true
  def event_time(event) do
    [time_string | _rest] =
      event
      |> Selectors.text(css(".calendar_info_doors_cover"))
      |> String.split()

    ParseHelpers.time_string_to_time(time_string)
  end

  @impl true
  def price(event) do
    event
    |> Selectors.text(css(".calendar_info_doors_cover a"))
    |> Price.new()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    event
    |> Selectors.match_one(css(".calendar_info_doors_cover a"))
    |> Selectors.attr("href")
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
