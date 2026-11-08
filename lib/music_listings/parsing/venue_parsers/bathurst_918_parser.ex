defmodule MusicListings.Parsing.VenueParsers.Bathurst918Parser do
  @moduledoc """
  Parser for extracting events from https://www.918bathurst.com/events

  The site is a React app that fills its listing in from its own database once the
  page has loaded, so a plain fetch has no events in it.  The page is fetched
  through Firecrawl (`firecrawl: true`), which renders it in a browser - about 1
  credit a night.

  The rendered page's "All Upcoming Events" grid has a card per event, i.e.

      <div class="group cursor-pointer">
        <div class="mb-2"><span>11/27/2026</span><span>$20.00</span></div>
        <h3>Westelaken - In it for the Lack - Album Release</h3>
        <p>📍 The Sanctuary</p>
      </div>

  The calendar beside it also renders a card for each event on the selected day,
  with different markup and no date line, so only cards with a date are read.

  A card's door and show times and its ticket link are only in a popup that's
  built when it's clicked, so they aren't in the rendered page: the time is left
  unknown and every event links to the events page.  Cards have no id, so the id
  is built from the title and date (the centre has several rooms, so two events
  can share a day).

  This used to read the venue's events from Dice, which only lists the shows
  ticketed through Dice - one of the seven on the site when this was changed.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://www.918bathurst.com/events"

  @card_date ~r/^\s*(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{4})\s*$/

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url, [], firecrawl: true) end
  end

  @impl true
  def events(body) do
    with {:ok, document} <- Selectors.parse(body) do
      document
      |> Selectors.all_matches(css("div.group.cursor-pointer"))
      |> Enum.map(&card/1)
      |> Enum.reject(&is_nil/1)
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_title_and_date("918_bathurst_#{event.title}", event.date)
  end

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
  def event_time(_event), do: nil

  @impl true
  def price(event), do: Price.new(event.price)

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  # A grid card, or nil for anything else matching the selector (the calendar's cards)
  defp card(card) do
    with [date_text | rest] <-
           card |> Selectors.all_matches(css("div.mb-2 > span")) |> Selectors.text(),
         {:ok, date} <- parse_date(date_text),
         title when is_binary(title) <- Selectors.text(card, css("h3")),
         title = String.trim(title),
         false <- title == "" do
      %{date: date, title: title, price: List.first(rest)}
    else
      _not_a_grid_card -> nil
    end
  end

  # "11/27/2026"
  defp parse_date(text) do
    case Regex.named_captures(@card_date, text) do
      %{"month" => month, "day" => day, "year" => year} ->
        ParseHelpers.build_date_from_year_month_day_strings(year, month, day)

      nil ->
        {:error, :invalid_date}
    end
  end
end
