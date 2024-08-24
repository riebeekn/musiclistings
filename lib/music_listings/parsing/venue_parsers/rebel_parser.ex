defmodule MusicListings.Parsing.VenueParsers.RebelParser do
  @moduledoc """
  Parser for extracing events from https://rebeltoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url,
    do:
      "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Frebeltoronto.com%2Fevents%2F&w=737e2434-3a70-460f-aa98-a1ec67d0b60b"

  @impl true
  def example_data_file_location, do: "test/data/rebel/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

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
  def ignored_event_id(event) do
    event_id(event)
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

      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
    else
      nil
    end
  end

  @impl true
  def event_end_date(_event) do
    nil
  end

  @impl true
  def event_time(event) do
    if is_map(event["start"]) do
      ParseHelpers.time_string_to_time(event["start"]["time"])
    else
      nil
    end
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
    event["buttonLink"]["rawValue"]
  end
end
