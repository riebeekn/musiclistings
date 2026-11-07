defmodule MusicListings.Parsing.VenueParsers.MossopsParser do
  @moduledoc """
  Parser for extracting events from https://mossops.ca/#happenings

  Mossop's Social House is the bar in Hotel Victoria.  The homepage's
  "Happenings" section lists the hotel's upcoming events as cards, each linking
  to its page on hotelvictoriatoronto.com.  Its live music is the
  "Live at Mossop's ft. <performer>" series; other hotel events (workshops and
  the like) are listed alongside it, so only the series is kept.

  Each card's `<time datetime>` carries the local start time with an offset,
  which `NaiveDateTime.from_iso8601/1` discards, leaving the wall-clock time we
  want.  The cards have no price, so it's unknown.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://mossops.ca/"
  @series_prefix ~r/^live at mossop.s\b/i
  @performer_prefix ~r/^live at mossop.s\s+(ft\.?|feat\.?|featuring)\s+/i

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("#happenings article.event"))
    |> Enum.filter(&(event_title(&1) =~ @series_prefix))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  # The card's id is "event-<wordpress post id>"
  @impl true
  def event_id(event) do
    event
    |> Selectors.attr("id")
    |> String.replace_prefix("event-", "mossops_")
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".event__heading"))
    |> String.trim()
  end

  # i.e. "Live at Mossop's ft. Alex Krolick"
  @impl true
  def performers(event) do
    event
    |> event_title()
    |> String.replace(@performer_prefix, "")
    |> List.wrap()
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event |> start_datetime() |> NaiveDateTime.to_date()

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event |> start_datetime() |> NaiveDateTime.to_time()

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(event) do
    Selectors.url(event, css("a.event__container"))
  end

  # i.e. "2026-11-11T18:30:00-05:00"
  defp start_datetime(event) do
    event
    |> Selectors.match_one(css("time.event__date"))
    |> Selectors.attr("datetime")
    |> NaiveDateTime.from_iso8601!()
  end
end
