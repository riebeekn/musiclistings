defmodule MusicListings.Parsing.VenueParsers.RexParser do
  @moduledoc """
  Parser for extracing events from https://www.therex.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url do
    today = Date.utc_today()

    "https://www.therex.ca/api/open/GetItemsByMonth?month=#{today.month}-#{today.year}&collectionId=62099f5a37eb917826df65cc&crumb=BZxZJlGW0oALYzcxZDM5MjgzOGE1NmQ0ZTcyOWY3NjdhZWFmMDVi"
  end

  @impl true
  def example_data_file_location, do: "test/data/rex/index.json"

  @impl true
  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  @impl true
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    event["id"]
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
    event["startDate"]
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_date()
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(_event) do
    nil
  end
end