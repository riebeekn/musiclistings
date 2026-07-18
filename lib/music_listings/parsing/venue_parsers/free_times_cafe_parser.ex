defmodule MusicListings.Parsing.VenueParsers.FreeTimesCafeParser do
  @moduledoc """
  Parser for extracting events from https://www.freetimescafe.com/entertainment.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  # Stable per-site component id and Boomtech Calendar's global Wix app id.
  @comp_id "comp-kw6rllyd"
  @calendar_app_def_id "13b4a028-00fa-7133-242f-4628106b8c91"

  @tokens_url "https://www.freetimescafe.com/_api/v1/access-tokens"
  @calendar_base "https://calendar.apiboomtech.com/api/published_calendar"

  # Categories we treat as musical: the dedicated "Music" category plus the
  # music-genre categories and open mics.  Matched by exact name, so e.g.
  # "Comedy Open Mic" is deliberately not caught by "Open Mic".
  @music_categories MapSet.new([
                      "Music",
                      "Jazz",
                      "Folk Music",
                      "Latin Music",
                      "Hip-Hop",
                      "Chilean Music",
                      "Klezmer",
                      "Turkish",
                      "Open Mic"
                    ])

  @impl true
  def source_url, do: "https://www.freetimescafe.com/entertainment"

  @impl true
  def retrieve_events_fun do
    fn _url ->
      with {:ok, instance} <- fetch_instance() do
        instance
        |> calendar_url()
        |> HttpClient.get(request_headers())
      end
    end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("events", [])
    |> Enum.filter(&(music?(&1) and upcoming?(&1)))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: to_string(event["id"])

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["title"]

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> start_naive_datetime()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event) do
    event
    |> start_naive_datetime()
    |> NaiveDateTime.to_time()
  end

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event) do
    # `link` is dirty in the feed: besides real URLs it holds the placeholder
    # "event_page", empty strings, and occasionally stray text.  Only trust it
    # when it's an actual http(s) link.
    case event["link"] do
      "http" <> _rest = url -> ParseHelpers.sanitize_ticket_url(url)
      _not_a_url -> nil
    end
  end

  @impl true
  def details_url(event), do: ticket_url(event)

  # ===========================================================================
  # Fetching
  # ===========================================================================
  defp fetch_instance do
    case HttpClient.get(@tokens_url, request_headers()) do
      {:ok, %Response{status: 200, body: body}} ->
        body
        |> ParseHelpers.maybe_decode!()
        |> get_in(["apps", @calendar_app_def_id, "instance"])
        |> case do
          instance when is_binary(instance) and instance != "" -> {:ok, instance}
          _missing -> {:error, :no_instance}
        end

      {:ok, %Response{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, _reason} = error ->
        error
    end
  end

  defp calendar_url(instance) do
    @calendar_base <>
      "?comp_id=#{@comp_id}" <>
      "&instance=#{URI.encode(instance)}" <>
      "&time_zone=America/Toronto"
  end

  defp request_headers do
    [
      {"accept", "application/json, text/plain, */*"},
      {"origin", "https://calendar.boomte.ch"},
      {"referer", "https://calendar.boomte.ch/"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"}
    ]
  end

  # ===========================================================================
  # Filtering
  # ===========================================================================
  defp music?(event) do
    (event["categories"] || [])
    |> Enum.any?(&MapSet.member?(@music_categories, &1["name"]))
  end

  defp upcoming?(event) do
    case parse_date(event["start"]) do
      %Date{} = date -> Date.compare(date, DateHelpers.today_eastern()) != :lt
      nil -> false
    end
  end

  # ===========================================================================
  # Datetime parsing
  #
  # `start` is a naive Eastern wall-clock string, usually without seconds
  # (e.g. "2026-07-18T20:00", occasionally "...T20:00:00").  No timezone
  # conversion is needed - we keep the wall-clock time as-is.
  # ===========================================================================
  defp start_naive_datetime(event) do
    [date, time] = String.split(event["start"], "T")
    NaiveDateTime.from_iso8601!("#{date}T#{ensure_seconds(time)}")
  end

  defp parse_date(start) when is_binary(start) do
    start
    |> String.split("T")
    |> List.first()
    |> Date.from_iso8601()
    |> case do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  defp parse_date(_start), do: nil

  defp ensure_seconds(time) do
    case String.split(time, ":") do
      [_hour, _minute] -> time <> ":00"
      _has_seconds -> time
    end
  end
end
