defmodule MusicListings.Parsing.VenueParsers.BaseParsers.MatoParser do
  @moduledoc """
  Base parser for venues listed on Mato (ma.to).

  The venue pages (ma.to/venue/<username>) are a client-rendered SPA, so we call
  Mato's JSON API directly instead of scraping HTML. Venue parsers pass their
  Mato username to `retrieve_events_fun/1` (to build the request) and to
  `events/2` (to scope the results), and delegate the rest of the `VenueParser`
  callbacks here.
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @base_url "https://ma.to"
  @api_url "https://api.ma.to"

  # The API paginates; the venues we track list well under this many upcoming
  # events, so we take a single page big enough to make pagination moot.
  @page_size 100

  def build_source_url(username), do: "#{@base_url}/venue/#{username}"

  def retrieve_events_fun(username) do
    fn _url ->
      url = events_api_url(username)
      HttpClient.get(url, request_headers())
    end
  end

  def events(body, username) do
    body
    |> ParseHelpers.maybe_decode!()
    |> get_in(["data", "events"])
    |> case do
      events when is_list(events) ->
        Enum.filter(events, &(&1["venueUsername"] == username))

      _unexpected_shape ->
        []
    end
  end

  def next_page_url(_body, _current_url), do: nil

  def event_id(event, venue_id_prefix), do: "#{venue_id_prefix}_#{event["id"]}"

  def event_title(event), do: event["title"]

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event
    |> start_naive_datetime()
    |> NaiveDateTime.to_date()
  end

  def additional_dates(_event), do: []

  def event_time(event) do
    event
    |> start_naive_datetime()
    |> NaiveDateTime.to_time()
  end

  def price(event) do
    cond do
      event["isFreePrice"] == true ->
        Price.new("free")

      is_number(event["priceNumeric"]) and event["priceNumeric"] > 0 ->
        Price.new("$#{event["priceNumeric"]}")

      is_binary(event["price"]) and event["price"] != "" ->
        Price.new(event["price"])

      true ->
        Price.unknown()
    end
  end

  def age_restriction(_event), do: :unknown

  def ticket_url(event), do: details_url(event)

  def details_url(event), do: "#{@base_url}/event/#{event["slug"]}"

  # Mato's startDate carries a timezone offset (e.g. "...T20:00:00.000-04:00").
  # NaiveDateTime.from_iso8601 discards the offset, giving us the local
  # wall-clock time - which is exactly what we want to display.
  defp start_naive_datetime(event) do
    NaiveDateTime.from_iso8601!(event["startDate"])
  end

  defp events_api_url(username) do
    "#{@api_url}/v1/events/venue/#{username}/upcoming?page=1&limit=#{@page_size}"
  end

  defp request_headers do
    [
      {"accept", "application/json"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"}
    ]
  end
end
