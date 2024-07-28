defmodule MusicListings.Parsing.VenueParsers.AxisClubParser do
  @moduledoc """
  Parser for extracing events from https://theaxisclub.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url, do: "https://theaxisclub.com/all-events"

  @impl true
  def example_data_file_location, do: "test/data/axis_club/index.html"

  @impl true
  def events(body) do
    body
    |> Meeseeks.parse()
    |> Meeseeks.one(css("script[type=\"application/ld+json\"]"))
    |> Meeseeks.data()
    |> Jason.decode!()
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    "#{event_title(event)}-#{event_date(event)}"
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
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
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
  def ticket_url(event) do
    event["url"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
