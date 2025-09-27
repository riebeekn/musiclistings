defmodule MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceJsonParser do
  @moduledoc """
  Base parser for SquareSpace venues that use JSON APIs with GetItemsByMonth endpoints
  """

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  def source_url(base_url, collection_id, crumb) do
    today = DateHelpers.today()

    "#{base_url}/api/open/GetItemsByMonth?month=#{today.month}-#{today.year}&collectionId=#{collection_id}&crumb=#{crumb}"
  end

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  def next_page_url(current_url, base_url, collection_id, crumb) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)

    next_page_url =
      "#{base_url}/api/open/GetItemsByMonth?month=#{next_month.month}-#{next_month.year}&collectionId=#{collection_id}&crumb=#{crumb}"

    if current_url == next_page_url do
      nil
    else
      next_page_url
    end
  end

  def event_id(event) do
    event["id"]
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event) do
    event["title"]
    |> ParseHelpers.fix_encoding()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event["startDate"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_date()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event["startDate"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_datetime()
    |> DateTime.to_time()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(_event) do
    nil
  end

  def details_url(event, base_url) do
    "#{base_url}/events/#{event["urlId"]}"
  end
end
