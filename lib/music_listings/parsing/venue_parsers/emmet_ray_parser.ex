defmodule MusicListings.Parsing.VenueParsers.EmmetRayParser do
  @moduledoc """
  Parser for extracing events from https://www.theemmetray.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.theemmetray.com/entertainment/events-2023/"

  @impl true
  def retrieve_events_fun do
    fn url -> Req.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/emmet_ray/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".fusion-events-post"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".fusion-events-meta h2"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> Selectors.text(css(".tribe-event-date-start"))
    |> String.split("/")
    |> Enum.at(0)
    |> String.split()
    |> case do
      [month_string, day_string] ->
        ParseHelpers.build_date_from_month_day_strings(month_string, day_string)

      [month_string, day_string, year_string] ->
        ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
    end
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css(".tribe-event-date-start"))
    |> String.split("/")
    |> Enum.at(1)
    |> ParseHelpers.build_time_from_time_string()
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
    Selectors.url(event, css(".fusion-events-meta h2 a"))
  end
end
