defmodule MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser do
  @moduledoc """
  Base parser for sites using admit one json data
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event, venue_name) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime(venue_name, date, time)
  end

  def event_title(event) do
    event["title"]
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    [month_string, day_string, year_string] = event["event_date"] |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event["doors"]
    |> ParseHelpers.build_time_from_time_string()
  end

  def price(event) do
    event["price_range"]
    |> Price.new()
  end

  def age_restriction(event) do
    event["age_limit"]
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  def ticket_url(event) do
    event["url"]
  end

  def details_url(_event) do
    nil
  end
end
