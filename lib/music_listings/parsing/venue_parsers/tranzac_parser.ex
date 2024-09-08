defmodule MusicListings.Parsing.VenueParsers.TranzacParser do
  @moduledoc """
  Parser for extracing events from https://www.tranzac.org/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url do
    today = DateHelpers.today()
    padded_month_string = today.month |> Integer.to_string() |> String.pad_leading(2, "0")

    "https://www.tranzac.org/events/month/#{today.year}-#{padded_month_string}/"
  end

  @impl true
  def example_data_file_location, do: "test/data/tranzac/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("article.tribe-events-calendar-month__calendar-event"))
  end

  @impl true
  def next_page_url(_body, current_url) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)
    padded_month_string = next_month.month |> Integer.to_string() |> String.pad_leading(2, "0")

    next_page_url =
      "https://www.tranzac.org/events/month/#{next_month.year}-#{padded_month_string}/"

    if current_url == next_page_url do
      nil
    else
      next_page_url
    end
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
    event
    |> Selectors.match_one(css(".tribe-events-calendar-month__calendar-event-title a"))
    |> Selectors.attr("title")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> Selectors.match_one(
      css("div.tribe-events-calendar-month__calendar-event-tooltip-datetime time")
    )
    |> Selectors.attr("datetime")
    |> Date.from_iso8601!()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    time_string =
      event
      |> Selectors.match_one(css("div.tribe-events-calendar-month__calendar-event-datetime time"))
      |> Selectors.attr("datetime")

    padded_time_string = "#{time_string}:00"
    Time.from_iso8601!(padded_time_string)
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
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(event) do
    event
    |> Selectors.url(css(".tribe-events-calendar-month__calendar-event-title a"))
  end
end