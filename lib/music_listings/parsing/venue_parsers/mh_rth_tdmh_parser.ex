defmodule MusicListings.Parsing.VenueParsers.MhRthTdmhParser do
  @moduledoc """
  Common parser functions for Massey Hall, Roy Thomson Hall and
  TD Music Hall, as they are on a single site
  """

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  def source_url, do: "https://www.mhrth.com/api/performance-feed/12"

  def event(body, facility_no) do
    body = ParseHelpers.maybe_decode!(body)

    body["result"]["GetPerformancesEx4Result"]["Performance"]
    |> Enum.filter(&(&1["cmsFacilityData"]["FacilityID"] == facility_no))
  end

  def next_page_url(_body), do: nil

  def event_id(event), do: event["perf_no"]

  def ignored_event_id(event), do: event_id(event)

  def event_title(event) do
    event["cmsData"]["Title"]
    |> String.trim()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event["perf_date"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  def event_time(event) do
    event["perf_date"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    "https://tickets.mhrth.com/#{event["prod_season_no"]}/#{event["perf_no"]}"
  end

  def details_url(_event) do
    nil
  end
end
