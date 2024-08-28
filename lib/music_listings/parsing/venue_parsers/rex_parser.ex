defmodule MusicListings.Parsing.VenueParsers.RexParser do
  @moduledoc """
  Parser for extracing events from https://www.therex.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url do
    today = DateHelpers.today()

    "https://www.therex.ca/api/open/GetItemsByMonth?month=#{today.month}-#{today.year}&collectionId=62099f5a37eb917826df65cc&crumb=BZxZJlGW0oALYzcxZDM5MjgzOGE1NmQ0ZTcyOWY3NjdhZWFmMDVi"
  end

  @impl true
  def example_data_file_location, do: "test/data/rex/index.json"

  @impl true
  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  @impl true
  def next_page_url(_body, current_url) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)

    next_page_url =
      "https://www.therex.ca/api/open/GetItemsByMonth?month=#{next_month.month}-#{next_month.year}&collectionId=62099f5a37eb917826df65cc&crumb=BZxZJlGW0oALYzcxZDM5MjgzOGE1NmQ0ZTcyOWY3NjdhZWFmMDVi"

    if current_url == next_page_url do
      nil
    else
      next_page_url
    end
  end

  @impl true
  def event_id(event) do
    event["id"]
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
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
    |> DateHelpers.to_eastern_date()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event["startDate"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_datetime()
    |> DateTime.to_time()
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
    "https://www.therex.ca/"
  end
end
