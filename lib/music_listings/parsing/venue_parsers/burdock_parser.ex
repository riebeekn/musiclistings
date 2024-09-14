defmodule MusicListings.Parsing.VenueParsers.BurdockParser do
  @moduledoc """
  Parser for extracing events from https://burdockbrewery.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url, do: "https://burdockbrewery.com/pages/music-hall"

  @impl true
  def example_data_file_location, do: "test/data/burdock/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".product-item"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
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
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".product__grid__title"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week, month, day, _separator, _time] =
      Selectors.text(event, css(".product-vendorgrid")) |> String.split()

    ParseHelpers.build_date_from_month_day_strings(month, day, DateHelpers.today())
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    [_day_of_week, _month, _day, _separator, time] =
      Selectors.text(event, css(".product-vendorgrid")) |> String.split()

    ParseHelpers.build_time_from_time_string(time)
  end

  @impl true
  def price(event) do
    event
    |> Selectors.text(css(".new-price"))
    |> Price.new()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    slug = Selectors.url(event, css(".product-link"))

    "https://burdockbrewery.com#{slug}"
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
