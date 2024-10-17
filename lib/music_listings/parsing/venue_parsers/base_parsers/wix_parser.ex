defmodule MusicListings.Parsing.VenueParsers.BaseParsers.WixParser do
  @moduledoc """
  Base parser for wix sites
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    event["id"]
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event) do
    event["title"]
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    {:ok, utc_datetime, _offset} =
      event["scheduling"]["config"]["startDate"]
      |> DateTime.from_iso8601()

    DateHelpers.to_eastern_date(utc_datetime)
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    {:ok, utc_datetime, _offset} =
      event["scheduling"]["config"]["startDate"]
      |> DateTime.from_iso8601()

    DateHelpers.to_eastern_time(utc_datetime)
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event["registration"]["external"]["registration"]
  end

  def details_url(_event) do
    nil
  end
end
