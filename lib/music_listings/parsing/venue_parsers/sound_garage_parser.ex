defmodule MusicListings.Parsing.VenueParsers.SoundGarageParser do
  @moduledoc """
  Parser for extracting events from https://dice.fm/venue/the-sound-garage-xeval
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://dice.fm/venue/the-sound-garage-xeval"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("script[type=\"application/ld+json\"]"))
    |> Enum.map(&Selectors.data/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.flat_map(&extract_music_events/1)
  end

  defp extract_music_events(json_string) do
    json_string
    |> Jason.decode!()
    |> Map.get("event", [])
    |> Enum.filter(&music_event?/1)
  end

  defp music_event?(%{"@type" => "MusicEvent"}), do: true
  defp music_event?(_non_music_event), do: false

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("sound_garage", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["name"]
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
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def additional_dates(_event) do
    []
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
