defmodule MusicListings.Parsing.VenueParsers.CestWhatParser do
  @moduledoc """
  Parser for extracting events from https://cestwhat.com/event-poster/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @event_regex ~r/(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s+(\d{1,2})\s+(.*?)\s*\|\s*(\d{1,2}(?::\d{2})?(?:am|pm)?)-(\d{1,2}(?::\d{2})?(?:am|pm))/i

  @impl true
  def source_url, do: "https://cestwhat.com/event-poster/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    alt_text =
      body
      |> Selectors.all_matches(css("img[alt]"))
      |> Enum.map(&Selectors.attr(&1, "alt"))
      |> Enum.find("", &String.contains?(&1, "What's Up"))

    @event_regex
    |> Regex.scan(alt_text)
    |> Enum.map(fn [_full, month, day, title, start_time, end_time] ->
      %{
        "month" => month,
        "day" => day,
        "title" => String.trim(title),
        "start_time" => normalize_start_time(start_time, end_time)
      }
    end)
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("cest_what", date, time)
  end

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
    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(event["month"], event["day"])
    date
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event) do
    case ParseHelpers.build_time_from_time_string(event["start_time"]) do
      {:ok, time} -> time
      _error -> nil
    end
  end

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: "https://cestwhat.com/event-poster/"

  defp normalize_start_time(start_time, end_time) do
    if String.match?(start_time, ~r/(am|pm)/i) do
      start_time
    else
      suffix = if String.match?(end_time, ~r/am/i), do: "am", else: "pm"
      start_time <> suffix
    end
  end
end
