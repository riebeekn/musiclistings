defmodule MusicListings.Parsing.VenueParsers.BudweiserStageParser do
  @moduledoc """
  Parser for extracing events from https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events"

  @impl true
  def example_data_file_location, do: "test/data/budweiser_stage/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> Enum.map(&Jason.decode!/1)
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
    Price.unknown()
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
