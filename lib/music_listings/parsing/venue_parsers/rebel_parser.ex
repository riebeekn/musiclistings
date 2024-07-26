defmodule MusicListings.Parsing.VenueParsers.RebelParser do
  @moduledoc """
  Parser for extracing events from https://rebeltoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url,
    do:
      "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Frebeltoronto.com%2Fevents%2F&w=737e2434-3a70-460f-aa98-a1ec67d0b60b"

  @impl true
  def example_data_file_location, do: "test/data/rebel/index.json"

  @impl true
  def event_selector(body) do
    # bit of a hack to facilitate pulling data locally... Req converts it
    # to a map when pulling from www, where-as locally we just have a file
    # so when pulling local we get a string and need to decode! it
    body = if is_binary(body), do: Jason.decode!(body), else: body

    body["data"]["widgets"]["737e2434-3a70-460f-aa98-a1ec67d0b60b"]["data"]["settings"]["events"]
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event["id"]
  end

  @impl true
  def event_title(event) do
    event["name"]
  end

  @impl true
  def performers(event) do
    [event["name"]]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    if is_map(event["start"]) do
      [year_string, month_string, day_string] = event["start"]["date"] |> String.split("-")

      year = String.to_integer(year_string)
      month = String.to_integer(month_string)
      day = String.to_integer(day_string)

      Date.new!(year, month, day)
    else
      nil
    end
  end

  @impl true
  def event_time(event) do
    if is_map(event["start"]) do
      [hour_string, minute_string] = event["start"]["time"] |> String.split(":")

      hour = String.to_integer(hour_string)
      minute = String.to_integer(minute_string)

      Time.new!(hour, minute, 0)
    else
      nil
    end
  end

  @impl true
  def price(_event) do
    ParseHelpers.convert_price_string_to_price(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    event["buttonLink"]["rawValue"]
  end
end
