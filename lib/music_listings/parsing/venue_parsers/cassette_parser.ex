defmodule MusicListings.Parsing.VenueParsers.CassetteParser do
  @moduledoc """
  Parser for extracting events from https://www.cassetteto.com

  Each event card shows its date without a year and its start time
  ("Sat, Oct 31 · 8pm · Karaoke").  A recurring event shows its schedule
  instead ("Every Saturday @ 8pm · Karaoke"), so for those the date comes from
  the event's slug, which always ends in the date (`cassette-karaoke-nov-07`).

  The venue also hosts trivia, karaoke, workshops and the like; only events in
  its "Live music" category are kept.

  The slug doubles as the event id: each occurrence of a recurring event has
  its own, and a slug isn't regenerated when an event is rescheduled, so a
  moved show updates in place rather than appearing twice.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://www.cassetteto.com"
  @live_music_category "Live music"

  # "Oct 31" in the card's date line
  @date_regex ~r/\b([A-Z][a-z]{2}) (\d{1,2})\b/
  # "nov-07" at the end of the event's slug
  @slug_date_regex ~r/-([a-z]{3})-(\d{1,2})$/
  # "8pm" or "6:30pm"
  @time_regex ~r/\b\d{1,2}(?::\d{2})?[ap]m\b/

  @impl true
  def source_url, do: "#{@base_url}/whats-on"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("article.event-card"))
    |> Enum.map(&build_event/1)
    |> Enum.filter(&(&1["category"] == @live_music_category))
  end

  defp build_event(card) do
    date_line = Selectors.text(card, css("p.text-muted-foreground"))
    path = Selectors.url(card, css("h3 a"))
    [month, day] = month_and_day(date_line, path)

    %{
      "slug" => Path.basename(path),
      "category" => category(date_line),
      "title" => card |> Selectors.text(css("h3 a")) |> String.trim(),
      "month" => month,
      "day" => day,
      "time" => time(date_line),
      "path" => path,
      # "Get tickets" links open the vendor in a new tab; cards without one
      # link to the restaurant's reservations page instead
      "ticket_url" => Selectors.url(card, css("a[target=\"_blank\"]"))
    }
  end

  defp month_and_day(date_line, path) do
    case Regex.run(@date_regex, date_line, capture: :all_but_first) do
      [month, day] -> [month, day]
      nil -> Regex.run(@slug_date_regex, path, capture: :all_but_first)
    end
  end

  # The category is the last part of the date line: "Sat, Oct 31 · 8pm · Karaoke"
  defp category(date_line) do
    date_line
    |> String.split("·")
    |> List.last()
    |> String.trim()
  end

  defp time(date_line) do
    case Regex.run(@time_regex, date_line) do
      [time] -> time
      nil -> nil
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: event["slug"]

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
  def event_time(event), do: ParseHelpers.time_from_time_string(event["time"])

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event), do: event["ticket_url"]

  @impl true
  def details_url(event), do: "#{@base_url}#{event["path"]}"
end
