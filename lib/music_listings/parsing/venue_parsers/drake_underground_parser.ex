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
  def events(body) do
    # bit of a hack to facilitate pulling data locally... Req converts it
    # to a map when pulling from www, where-as locally we just have a file
    # so when pulling local we get a string and need to decode! it
    if is_binary(body), do: Jason.decode!(body), else: body
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    to_string(event["id"])
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

    year = String.to_integer(year_string)
    month = String.to_integer(month_string)
    day = String.to_integer(day_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event["fm_time"]
    |> Enum.at(0)
    |> ParseHelpers.time_string_to_time()
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(event) do
    event["fm_filter_1"]
    |> Enum.at(0)
    |> ParseHelpers.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    event["link"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
