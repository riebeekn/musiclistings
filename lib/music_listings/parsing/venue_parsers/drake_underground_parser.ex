defmodule MusicListings.Parsing.VenueParsers.DrakeUndergroundParser do
  @moduledoc """
  Parser for extracing events from https://www.thedrake.ca/thedrakehotel/underground/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url,
    do: "https://www.thedrake.ca/wp-json/drake/v2/drake_events"

  @impl true
  def example_data_file_location, do: "test/data/drake_underground/index.json"

  @impl true
  def retrieve_events_fun do
    fn url -> HTTPoison.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Enum.filter(&(&1["fm_venue"] == ["Drake Underground"]))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    to_string(event["id"])
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    primary_title = event["title"]["rendered"] |> String.trim()
    backup_title = event["fm_title_short"] |> Enum.at(0)
    if primary_title == "", do: backup_title, else: primary_title
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [year_string, month_string, day_string] = event["fm_date"] |> Enum.at(0) |> String.split("-")

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event["fm_time"]
    |> Enum.at(0)
    |> ParseHelpers.build_time_from_time_string()
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(event) do
    event["fm_filter_1"]
    |> Enum.at(0)
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    event["fm_cta_url"]
  end

  @impl true
  def details_url(event) do
    event["link"]
  end
end
