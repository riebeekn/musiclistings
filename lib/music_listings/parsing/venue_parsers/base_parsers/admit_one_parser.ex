defmodule MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser do
  @moduledoc """
  Base parser for sites using admit one json data
  """

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  def ignored_event_id(event) do
    event_id(event)
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
    |> ParseHelpers.time_string_to_time()
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