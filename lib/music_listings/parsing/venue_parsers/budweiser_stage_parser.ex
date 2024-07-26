defmodule MusicListings.Parsing.VenueParsers.BudweiserStageParser do
  @moduledoc """
  Parser for extracing events from https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url, do: "https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events"

  @impl true
  def example_data_file_location, do: "test/data/budweiser_stage/index.html"

  @impl true
  def event(body) do
    body
    |> Meeseeks.parse()
    |> Meeseeks.all(css("script[type=\"application/ld+json\"]"))
    |> Enum.map(&(&1 |> Meeseeks.data() |> Jason.decode!()))
    |> Enum.filter(&(&1["@type"] == "MusicEvent"))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event["url"]
    |> String.replace("https://www.livenation.com/event", "")
    |> String.replace("/", "")
  end

  @impl true
  def event_title(event) do
    event["name"]
  end

  @impl true
  def performers(event) do
    event["performers"]
    |> Enum.map(& &1["name"])
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def event_time(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
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
    event["url"]
  end
end
