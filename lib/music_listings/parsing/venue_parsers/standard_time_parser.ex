defmodule MusicListings.Parsing.VenueParsers.StandardTimeParser do
  @moduledoc """
  Parser for extracting events from https://standardtime.to/club

  Standard Time's public site embeds events via Dice's DiceEventListWidget,
  so we hit Dice's partner API directly (the same one the widget calls) and
  filter to `venue=Standard Time`.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @api_key "fQbYDR8nbsDkL63coCh1M5wZOWuc1_mIRJF8G2QAfBfxs2qa"

  @source_url "https://partners-endpoint.dice.fm/api/v2/events?page%5Bsize%5D=24&types=linkout%2Cevent&filter%5Bvenues%5D%5B%5D=Standard+Time&filter%5Bflags%5D%5B%5D=going_ahead&filter%5Bflags%5D%5B%5D=rescheduled"

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url ->
      HttpClient.get(url, [
        {"x-api-key", @api_key},
        {"origin", "https://standardtime.to"},
        {"referer", "https://standardtime.to/"}
      ])
    end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("data", [])
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: "standard_time_" <> event["id"]

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["name"]

  @impl true
  def performers(event) do
    (event["artists"] || [])
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> parse_event_datetime()
    |> DateHelpers.to_eastern_date()
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event) do
    event
    |> parse_event_datetime()
    |> DateHelpers.to_eastern_time()
  end

  @impl true
  def price(event) do
    face_values =
      event
      |> Map.get("ticket_types", [])
      |> Enum.map(& &1["price"])
      |> Enum.reject(&is_nil/1)
      |> Enum.map(& &1["face_value"])
      |> Enum.reject(&is_nil/1)

    case face_values do
      [] ->
        Price.unknown()

      values ->
        lo = values |> Enum.min() |> cents_to_dollars()
        hi = values |> Enum.max() |> cents_to_dollars()
        Price.new("$#{lo}-$#{hi}")
    end
  end

  @impl true
  def age_restriction(event) do
    ParseHelpers.age_restriction_string_to_enum(event["age_limit"])
  end

  @impl true
  def ticket_url(event), do: event["url"]

  @impl true
  def details_url(event), do: event["url"]

  defp parse_event_datetime(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["date"])
    datetime
  end

  defp cents_to_dollars(cents) do
    :erlang.float_to_binary(cents / 100, decimals: 2)
  end
end
