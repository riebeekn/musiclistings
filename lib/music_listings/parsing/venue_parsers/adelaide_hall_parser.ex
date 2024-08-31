defmodule MusicListings.Parsing.VenueParsers.AdelaideHallParser do
  @moduledoc """
  Parser for extracing events from https://www.adelaidehallto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url,
    do:
      "https://gateway.admitone.com/embed/live-events?venueId=6201607c4ece4990eeeb6a3c&order=asc"

  @impl true
  def example_data_file_location, do: "test/data/adelaide_hall/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  @impl true
  def next_page_url(_body, _current_url) do
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
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [month_string, day_string, year_string] = event["event_date"] |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event["doors"]
    |> ParseHelpers.time_string_to_time()
  end

  @impl true
  def price(event) do
    event["price_range"]
    |> Price.new()
  end

  @impl true
  def age_restriction(event) do
    event["age_limit"]
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    event["url"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
