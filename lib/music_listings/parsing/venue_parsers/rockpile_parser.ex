defmodule MusicListings.Parsing.VenueParsers.RockpileParser do
  @moduledoc """
  Parser for extracing events from https://rockpilerockbar.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://rockpilerockbar.com/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".tw-section"))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("rockpile", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".tw-name a"))
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    date_string = Selectors.text(event, css(".tw-event-date"))

    [month_string, raw_day_string, year_string] = String.split(date_string, " ")
    day_string = String.replace(raw_day_string, ",", "")

    {:ok, date} =
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)

    date
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    case event
         |> Selectors.text(css(".tw-event-time"))
         |> ParseHelpers.build_time_from_time_string() do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Selectors.text(css(".tw-age-restriction"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".tw-info-price-buy-tix a"))
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
