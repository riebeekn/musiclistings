defmodule MusicListings.Parsing.VenueParsers.MyHouseParser do
  @moduledoc """
  Parser for extracting events from https://myhouseinthejunction.com/live-entertainment

  The site is built with LeadConnector's page builder, and the calendar is a grid of
  hand typed headings, a pair per show, i.e.

      <h3>NOVEMBER 2026</h3>
      ...
      <h4>Friday November 6, 8PM</h4>
      <h4>GLENDALE ONE 🎤</h4>

  so `events/1` pairs each `<h4>` that reads as a date with the `<h4>` after it.
  Because it's typed by hand:

  - The date has no year.  It's taken from the calendar's month heading, moved a
    year either way for a show across a new year from it.  Shows from previous
    months are sometimes left on the page; they're in the past, so the crawler
    drops them.
  - The time is sometimes missing, e.g. `Saturday November 7`.
  - Titles carry an emoji (🎤, 🎹), which is removed.

  Nights closed for a private function and the monthly burlesque show are skipped.

  The page's ld+json `Event`s aren't used: they're months out of date.

  Shows have no id or page of their own, so the id is built from the date and every
  show links to the calendar.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://myhouseinthejunction.com/live-entertainment"

  @calendar_month ~r/^\s*(?<month>[a-z]+)\s+(?<year>20\d{2})\s*$/iu
  # "Friday November 6, 8PM", "Saturday November 7"
  @date_line ~r/^\s*(?:[a-z]+day\s+)?(?<month>[a-z]+)\.?\s+(?<day>\d{1,2})(?:st|nd|rd|th)?\s*(?:,\s*(?<time>.*?))?\s*$/iu
  @skipped_title ~r/\bclosed\b|burlesque/iu
  # Emoji and the joiners / variation selectors that build them
  @symbols ~r/[\p{So}\p{Sk}\x{FE0F}\x{200D}]/u

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    with {:ok, document} <- Selectors.parse(body) do
      calendar_month = calendar_month(document)

      document
      |> Selectors.all_matches(css("h4"))
      |> Enum.map(&(&1 |> Selectors.text() |> clean_text()))
      |> Enum.reject(&(&1 == ""))
      |> pair_shows(calendar_month, [])
      |> Enum.reject(&(&1.title =~ @skipped_title))
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: ParseHelpers.build_id_from_venue_and_date("my_house", event.date)

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event.title

  @impl true
  def performers(event) do
    [event.title]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event.date

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event.time

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  # A date line followed by the show's title
  defp pair_shows([date_line, title | rest], calendar_month, shows) do
    case parse_date_line(date_line, calendar_month) do
      {:ok, date, time} ->
        pair_shows(rest, calendar_month, [%{date: date, time: time, title: title} | shows])

      :error ->
        pair_shows([title | rest], calendar_month, shows)
    end
  end

  defp pair_shows(_rest, _calendar_month, shows), do: Enum.reverse(shows)

  defp parse_date_line(line, calendar_month) do
    with %{"month" => month, "day" => day, "time" => time} <-
           Regex.named_captures(@date_line, line),
         {:ok, date} <- build_date(month, day, calendar_month) do
      {:ok, date, ParseHelpers.time_from_time_string(time)}
    else
      _not_a_date -> :error
    end
  end

  defp build_date(month, day, nil), do: ParseHelpers.build_date_from_month_day_strings(month, day)

  # The calendar's year, unless the show is across a new year from its month
  defp build_date(month, day, calendar_month) do
    with {:ok, date} <-
           ParseHelpers.build_date_from_year_month_day_strings(
             "#{calendar_month.year}",
             month,
             day
           ) do
      cond do
        Date.diff(date, calendar_month) < -180 -> {:ok, Date.shift(date, year: 1)}
        Date.diff(date, calendar_month) > 180 -> {:ok, Date.shift(date, year: -1)}
        true -> {:ok, date}
      end
    end
  end

  # The first of the calendar's month, from its "NOVEMBER 2026" heading
  defp calendar_month(document) do
    document
    |> Selectors.all_matches(css("h3"))
    |> Enum.find_value(fn heading ->
      with %{"month" => month, "year" => year} <-
             Regex.named_captures(@calendar_month, Selectors.text(heading)),
           {:ok, date} <- ParseHelpers.build_date_from_year_month_day_strings(year, month, "1") do
        date
      else
        _not_the_month -> nil
      end
    end)
  end

  defp clean_text(text) do
    text
    |> String.replace(@symbols, "")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end
end
