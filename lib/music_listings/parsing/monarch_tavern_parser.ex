defmodule MusicListings.Parsing.MonarchTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.themonarchtavern.com/
  """
  @behaviour MusicListings.Parsing.Parser

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url do
    unix_today_in_milliseconds =
      (Date.utc_today() |> DateTime.new!(~T[00:00:00]) |> DateTime.to_unix()) * 1_000

    "https://tockify.com/api/ngevent?max=48&view=agenda&calname=monarchtavern&start-inclusive=true&longForm=false&showAll=false&startms=#{unix_today_in_milliseconds}"
  end

  @impl true
  def venue_name, do: "The Monarch Tavern"

  @impl true
  def example_data_file_location, do: "test/data/monarch_tavern/index.json"

  @impl true
  def event_selector(body) do
    # bit of a hack to facilitate pulling data locally... Req converts it
    # to a map when pulling from www, where-as locally we just have a file
    # so when pulling local we get a string and need to decode! it
    body = if is_binary(body), do: Jason.decode!(body), else: body

    body["events"]
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event["calid"]
  end

  @impl true
  def event_title(event) do
    event["content"]["summary"]["text"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["when"]["start"]["millis"]
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_date()
  end

  @impl true
  def event_time(_event) do
    nil
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
    event["content"]["customButtonLink"]
  end
end
