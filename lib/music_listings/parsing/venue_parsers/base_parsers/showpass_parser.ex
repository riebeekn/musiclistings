defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ShowpassParser do
  @moduledoc """
  Base parser for venues that sell through Showpass (https://www.showpass.com)

  Venue sites embed a Showpass widget that is rendered entirely in JavaScript,
  so we read the public events API behind it instead. Results are paged and
  the response carries the URL of the next page, if any.
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @doc """
  Builds the Showpass events API URL for a given numeric venue id.
  """
  def build_source_url(venue_id) do
    now_iso = DateHelpers.now() |> DateTime.to_iso8601()

    "https://www.showpass.com/api/public/events/" <>
      "?ends_on__gte=#{now_iso}" <>
      "&only_parents=true" <>
      "&ordering=starts_on,id" <>
      "&page=1" <>
      "&page_size=50" <>
      "&venue__in=#{venue_id}"
  end

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("results", [])
    |> Enum.filter(&listable?/1)
  end

  defp listable?(event) do
    event["show_on_calendar"] != false and
      is_nil(event["date_time_to_be_determined"]) and
      is_binary(event["starts_on"])
  end

  def next_page_url(body, _current_url) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("next")
  end

  def event_id(event) do
    event["slug"]
  end

  def event_title(event) do
    event["name"]
    |> String.trim()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    {:ok, utc_datetime, _offset} = DateTime.from_iso8601(event["starts_on"])

    DateHelpers.to_eastern_date(utc_datetime)
  end

  def additional_dates(_event) do
    []
  end

  # local_starts_on carries the venue's wall-clock time with its offset,
  # e.g. "2026-02-04T20:30:00-05:00", so the time portion can be used as-is
  def event_time(event) do
    case event["local_starts_on"] do
      nil ->
        nil

      local_starts_on ->
        local_starts_on
        |> String.slice(11, 8)
        |> Time.from_iso8601!()
    end
  end

  # An event can have several ticket tiers (GA / student / early bird) so the
  # price is the spread across all of them
  def price(event) do
    case event["ticket_types"] do
      [_first_ticket_type | _rest] = ticket_types ->
        ticket_types
        |> Enum.reject(& &1["is_password_protected"])
        |> Enum.map_join(",", & &1["price"])
        |> Price.new()

      _no_ticket_types ->
        Price.unknown()
    end
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event["frontend_details_url"]
  end

  def details_url(event) do
    event["frontend_details_url"]
  end
end
