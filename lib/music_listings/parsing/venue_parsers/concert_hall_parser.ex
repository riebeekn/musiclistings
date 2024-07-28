defmodule MusicListings.Parsing.VenueParsers.ConcertHallParser do
  @moduledoc """
  Parser for extracing events from https://888yonge.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url, do: "https://888yonge.com"

  @impl true
  def example_data_file_location, do: "test/data/concert_hall/index.html"

  @impl true
  def events(body) do
    body
    |> Meeseeks.parse()
    |> Meeseeks.all(css("script[type=\"application/ld+json\"]"))
    |> Enum.map(&(&1 |> Meeseeks.data() |> clean_extra_quotes() |> Jason.decode!()))
  end

  defp clean_extra_quotes(json_string) do
    # Regular expression to find extraneous quotes
    regex = ~r/":\s*"[^"]*",\s*"/

    cleaned_json =
      Regex.replace(regex, json_string, fn match ->
        String.replace(match, ",\"", ",")
      end)

    cleaned_json
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

  defp fix_event_datetime_string(dt_string) do
    # dt string is of format 2024-08-31T19:00
    # but we need 2024-08-31T19:00:00-04:00
    "#{dt_string}:00-04:00"
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> fix_event_datetime_string()
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def event_time(event) do
    "#{event["startDate"]}"
    |> fix_event_datetime_string()
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
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
    event["offers"]["url"]
  end
end
