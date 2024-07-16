defmodule MusicListings.Parsing.RoyThomsonHallParser do
  @moduledoc """
  Parser for extracing events from https://masseyhall.mhrth.com/
  """
  @behaviour MusicListings.Parsing.Parser

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers

  @roy_thomson_hall_facility_no "12"

  @impl true
  def source_url, do: "https://www.mhrth.com/api/performance-feed/12"

  @impl true
  def venue_name, do: "Roy Thomson Hall"

  @impl true
  def example_data_file_location, do: "test/data/massey_hall/index.json"

  @impl true
  def event_selector(body) do
    decoded_body = Jason.decode!(body)

    decoded_body["result"]["GetPerformancesEx4Result"]["Performance"]
    |> Enum.filter(&(&1["facility_no"] == @roy_thomson_hall_facility_no))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event["perf_no"]
  end

  @impl true
  def event_title(event) do
    event["cmsData"]["Title"]
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["perf_date"])
    DateTime.to_date(datetime)
  end

  @impl true
  def event_time(event) do
    regex = ~r/T(\d{2}:\d{2}:\d{2})([+-]\d{2}:\d{2})/
    [_full_string, time_string, _offset] = Regex.run(regex, event["perf_date"])
    Time.from_iso8601!(time_string)
  end

  @impl true
  def price(_event) do
    Parser.convert_price_string_to_price(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    "https://tickets.mhrth.com/#{event["prod_season_no"]}/#{event["perf_no"]}"
  end
end
