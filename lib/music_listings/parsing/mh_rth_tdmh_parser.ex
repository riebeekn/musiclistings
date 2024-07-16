defmodule MusicListings.Parsing.MhRthTdmhParser do
  @moduledoc """
  Common parser functions for Massey Hall, Roy Thomson Hall and
  TD Music Hall, as they are on a single site
  """

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers

  def source_url, do: "https://www.mhrth.com/api/performance-feed/12"

  def event_selector(body, facility_no) do
    # bit of a hack to facilitate pulling data locally... Req converts it
    # to a map when pulling from www, where-as locally we just have a file
    # so when pulling local we get a string and need to decode! it
    body = if is_binary(body), do: Jason.decode!(body), else: body

    body["result"]["GetPerformancesEx4Result"]["Performance"]
    |> Enum.filter(&(&1["facility_no"] == facility_no))
  end

  def next_page_url(_body), do: nil

  def event_id(event), do: event["perf_no"]

  def event_title(event) do
    event["cmsData"]["Title"]
    |> String.trim()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["perf_date"])
    DateTime.to_date(datetime)
  end

  def event_time(event) do
    regex = ~r/T(\d{2}:\d{2}:\d{2})([+-]\d{2}:\d{2})/
    [_full_string, time_string, _offset] = Regex.run(regex, event["perf_date"])
    Time.from_iso8601!(time_string)
  end

  def price(_event) do
    Parser.convert_price_string_to_price(nil)
  end

  def age_restriction(_event) do
    :tbd
  end

  def ticket_url(event) do
    "https://tickets.mhrth.com/#{event["prod_season_no"]}/#{event["perf_no"]}"
  end
end
