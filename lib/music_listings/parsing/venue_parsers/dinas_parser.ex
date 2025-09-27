defmodule MusicListings.Parsing.VenueParsers.DinasParser do
  @moduledoc """
  Parser for extracting events from https://www.dinastavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url do
    today = DateHelpers.today()

    "https://www.dinastavern.com/api/open/GetItemsByMonth?month=#{today.month}-#{today.year}&collectionId=68ae25e366b1226c46621c27&crumb=BSnq4OaZLAN4MjM2MDY2ZmIyYmRkZWJmYjA0MWM3YTk2ZTRmNmE0"
  end

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/dinas/index.json"

  @impl true
  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  @impl true
  def next_page_url(_body, current_url) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)

    next_page_url =
      "https://www.dinastavern.com/api/open/GetItemsByMonth?month=#{next_month.month}-#{next_month.year}&collectionId=68ae25e366b1226c46621c27&crumb=BSnq4OaZLAN4MjM2MDY2ZmIyYmRkZWJmYjA0MWM3YTk2ZTRmNmE0"

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
    |> ParseHelpers.fix_encoding()
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
  def details_url(event) do
    "https://www.dinastavern.com/events/#{event["urlId"]}"
  end
end
