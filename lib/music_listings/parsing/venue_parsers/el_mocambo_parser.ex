defmodule MusicListings.Parsing.VenueParsers.ElMocamboParser do
  @moduledoc """
  Parser for extracing events from https://elmocambo.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://elmocambo.com/events-new/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".bdt-event-item"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("el_mocambo", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".bdt-event-title-wrap a"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    %{"year" => year_string, "month" => month_string, "day" => day_string, "time" => _time_string} =
      parse_out_full_date_time_string(event)

    {:ok, date} =
      if year_string == "" do
        ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
      else
        ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
      end

    date
  end

  defp parse_out_full_date_time_string(event) do
    full_date_and_time_string =
      event
      |> Selectors.match_one(css(".bdt-event-date a"))
      |> Selectors.attr("title")

    regex =
      ~r/Start Date:(?<month>\w+)\s(?<day>\d{1,2})(,?\s(?<year>\d{4}))?\s@\s(?<time>[\d:]+\s[ap]m)/

    Regex.named_captures(regex, full_date_and_time_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    %{
      "year" => _year_string,
      "month" => _month_string,
      "day" => _day_string,
      "time" => time_string
    } =
      parse_out_full_date_time_string(event)

    case ParseHelpers.build_time_from_time_string(time_string) do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  @impl true
  def price(_event) do
    Price.unknown()
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
    Selectors.url(event, css(".bdt-event-title-wrap a"))
  end
end
