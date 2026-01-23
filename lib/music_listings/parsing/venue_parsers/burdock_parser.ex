defmodule MusicListings.Parsing.VenueParsers.BurdockParser do
  @moduledoc """
  Parser for extracing events from https://burdockbrewery.com via Showpass API
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @venue_id 17_330

  @impl true
  def source_url do
    now_iso = DateHelpers.now() |> DateTime.to_iso8601()

    "https://www.showpass.com/api/public/events/" <>
      "?ends_on__gte=#{now_iso}" <>
      "&only_parents=true" <>
      "&ordering=starts_on,id" <>
      "&page=1" <>
      "&page_size=50" <>
      "&venue__in=#{@venue_id}"
  end

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["results"]
  end

  @impl true
  def next_page_url(body, _current_url) do
    body = ParseHelpers.maybe_decode!(body)

    body["next"]
  end

  @impl true
  def event_id(event) do
    event["id"]
    |> to_string()
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
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    {:ok, utc_datetime, _offset} =
      event["starts_on"]
      |> DateTime.from_iso8601()

    DateHelpers.to_eastern_date(utc_datetime)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    case event["local_starts_on"] do
      nil ->
        nil

      local_starts_on ->
        # Parse just the time portion from the ISO8601 string to preserve local time
        # e.g. "2026-02-04T20:30:00-05:00" -> "20:30:00"
        local_starts_on
        |> String.split("T")
        |> List.last()
        |> String.split("-")
        |> List.first()
        |> String.split("+")
        |> List.first()
        |> Time.from_iso8601!()
    end
  end

  @impl true
  def price(event) do
    case event["ticket_types"] do
      [first_ticket | _rest] ->
        first_ticket["price"]
        |> Price.new()

      _other ->
        Price.unknown()
    end
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    event["frontend_details_url"]
  end

  @impl true
  def details_url(event) do
    event["frontend_details_url"]
  end
end
