defmodule MusicListings.Parsing.VenueParsers.HarbourfrontCentreParser do
  @moduledoc """
  Parser for extracting events from https://harbourfrontcentre.com/program/music/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://harbourfrontcentre.com/program/music/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("div.event-card"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    ParseHelpers.build_id_from_venue_and_date("harbourfront_centre", date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css("h3"))
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    date_time_string = Selectors.text(event, css(".card-body-date"))

    {:ok, date} =
      if multi_day_event?(date_time_string) do
        [start_date_string, end_date_string] =
          String.split(date_time_string, ~r/\s*↑\s*/, parts: 2)

        [_weekday, month_and_day] = String.split(start_date_string, ",")
        [month, day] = month_and_day |> String.trim() |> String.split(" ")
        [_weekday, _month_and_day, year] = String.split(end_date_string, ",")
        ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
      else
        [date_string, _time_string] = String.split(date_time_string, "•")
        [_weekday, month_and_day, year] = String.split(date_string, ",")
        [month, day] = month_and_day |> String.trim() |> String.split(" ")
        ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
      end

    date
  end

  defp multi_day_event?(date_string), do: String.contains?(date_string, "↑")

  @impl true
  def additional_dates(event) do
    date_time_string = Selectors.text(event, css(".card-body-date"))

    if multi_day_event?(date_time_string) do
      [_start_date_string, end_date_string] =
        String.split(date_time_string, ~r/\s*↑\s*/, parts: 2)

      [_weekday, month_and_day, year] = String.split(end_date_string, ",")
      [month, day] = month_and_day |> String.trim() |> String.split(" ")
      {:ok, end_date} = ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
      start_date = event_date(event)

      Date.range(start_date, end_date)
      |> Enum.to_list()
      # Drop the first date as it's the primary event_date
      |> Enum.drop(1)
    else
      []
    end
  end

  @impl true
  def event_time(event) do
    date_time_string = Selectors.text(event, css(".card-body-date"))

    if multi_day_event?(date_time_string) do
      nil
    else
      [_date_string, time_string] = String.split(date_time_string, "•")

      case ParseHelpers.build_time_from_time_string(time_string) do
        {:ok, time} -> time
        {:error, _reason} -> nil
      end
    end
  end

  @impl true
  def price(event) do
    event
    |> Selectors.text(css(".price-note"))
    |> Price.new()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(event) do
    event
    |> Selectors.match_one(css("a"))
    |> Selectors.attr("href")
  end
end
