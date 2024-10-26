defmodule MusicListings.Parsing.VenueParsers.JazzBistroParser do
  @moduledoc """
  Parser for extracing events from https://jazzbistro.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url do
    today = DateHelpers.today()
    padded_month_string = today.month |> Integer.to_string() |> String.pad_leading(2, "0")

    "https://jazzbistro.ca/event-calendar/month/#{today.year}-#{padded_month_string}/"
  end

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/jazz_bistro/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.match_one(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> Jason.decode!()
    |> Enum.filter(&(&1["@type"] == "Event"))
  end

  @impl true
  def next_page_url(_body, current_url) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)
    padded_month_string = next_month.month |> Integer.to_string() |> String.pad_leading(2, "0")

    next_page_url =
      "https://jazzbistro.ca/event-calendar/month/#{next_month.year}-#{padded_month_string}/"

    if current_url == next_page_url do
      nil
    else
      next_page_url
    end
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("jazz_bistro", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["name"]
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
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
    event["url"]
  end
end
