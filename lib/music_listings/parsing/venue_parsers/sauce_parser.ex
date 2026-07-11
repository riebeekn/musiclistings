defmodule MusicListings.Parsing.VenueParsers.SauceParser do
  @moduledoc """
  Parser for extracting events from https://sauceonthedanforth.com/live-music

  Sauce runs a hand-maintained BaseKit site with no structured event markup.
  Events are laid out as monthly sections - an `<h3>` header like "July 2026"
  followed by free-text lines like "Sat 04 Sal Indigo & Janet Christie". The
  month/year come from the section header, the day and performer from the line,
  and there is no per-event time.

  We flatten the page to text, split it into sections at each month/year header,
  and pull `<weekday> <day> <performer>` runs out of each section.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://sauceonthedanforth.com/live-music"

  @header_regex ~r/(January|February|March|April|May|June|July|August|September|October|November|December)\s+(20\d\d)/

  # A "<weekday> <day> <performer>" run, where the performer text extends up to
  # the next event, the next month header, or the end of the section.
  @event_regex ~r/(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*\s+(\d{1,2})\s+(.+?)(?=\s+(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*\s+\d{1,2}\b|\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d\d|$)/

  # Placeholder listings we don't want to surface as real events.
  @skip_titles ["", "TBA"]

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    text =
      body
      |> Selectors.match_one(css("body"))
      |> Meeseeks.text()
      |> String.replace(" ", " ")
      |> String.replace(~r/\s+/, " ")

    text
    |> month_sections()
    |> Enum.flat_map(fn {month, year, section_text} ->
      @event_regex
      |> Regex.scan(section_text)
      |> Enum.map(fn [_full, day, performer] ->
        %{"month" => month, "year" => year, "day" => day, "title" => clean_title(performer)}
      end)
    end)
    |> Enum.reject(&(&1["title"] in @skip_titles))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_date("sauce", event_date(event))
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
    {:ok, date} =
      ParseHelpers.build_date_from_year_month_day_strings(
        event["year"],
        event["month"],
        event["day"]
      )

    date
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(_event), do: nil

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  # Splits the flattened page text into {month, year, section_text} tuples, one
  # per month/year header, where section_text runs from just after the header to
  # the start of the next header (or the end of the text).
  defp month_sections(text) do
    matches = Regex.scan(@header_regex, text, return: :index)

    matches
    |> Enum.with_index()
    |> Enum.map(fn {[{full_start, full_length}, {ms, ml}, {ys, yl}], index} ->
      section_start = full_start + full_length

      section_end =
        case Enum.at(matches, index + 1) do
          [{next_start, _length} | _rest] -> next_start
          nil -> byte_size(text)
        end

      month = binary_part(text, ms, ml)
      year = binary_part(text, ys, yl)
      section_text = binary_part(text, section_start, section_end - section_start)

      {month, year, section_text}
    end)
  end

  defp clean_title(performer) do
    performer
    |> String.split("©")
    |> List.first()
    |> String.trim()
  end
end
