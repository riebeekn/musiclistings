defmodule MusicListings.Parsing.VenueParsers.BaseParsers.DiceParser do
  @moduledoc """
  Base parser for venues using Dice's partner API.

  Venues that embed `DiceEventListWidget` on their site are backed by
  `partners-endpoint.dice.fm/api/v2/events`. Venue parsers construct their
  `source_url` via `build_source_url/1` (which filters by venue name) and
  delegate the rest of the `VenueParser` callbacks here.
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @api_key "fQbYDR8nbsDkL63coCh1M5wZOWuc1_mIRJF8G2QAfBfxs2qa"
  @base_url "https://partners-endpoint.dice.fm/api/v2/events"

  def build_source_url(venue_name) do
    query =
      URI.encode_query([
        {"page[size]", "24"},
        {"types", "linkout,event"},
        {"filter[venues][]", venue_name},
        {"filter[flags][]", "going_ahead"},
        {"filter[flags][]", "rescheduled"}
      ])

    "#{@base_url}?#{query}"
  end

  def retrieve_events_fun do
    fn url -> HttpClient.get(url, [{"x-api-key", @api_key}]) end
  end

  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("data", [])
  end

  def next_page_url(_body, _current_url), do: nil

  def event_id(event, venue_id_prefix), do: "#{venue_id_prefix}_" <> event["id"]

  def event_title(event), do: event["name"]

  def performers(event) do
    (event["artists"] || [])
    |> Performers.new()
  end

  def event_date(event) do
    event
    |> parse_event_datetime()
    |> DateHelpers.to_eastern_date()
  end

  def additional_dates(_event), do: []

  def event_time(event) do
    event
    |> parse_event_datetime()
    |> DateHelpers.to_eastern_time()
  end

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

  def age_restriction(event) do
    ParseHelpers.age_restriction_string_to_enum(event["age_limit"])
  end

  def ticket_url(event), do: event["url"]

  def details_url(event), do: event["url"]

  defp parse_event_datetime(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["date"])
    datetime
  end

  defp cents_to_dollars(cents) do
    :erlang.float_to_binary(cents / 100, decimals: 2)
  end
end
