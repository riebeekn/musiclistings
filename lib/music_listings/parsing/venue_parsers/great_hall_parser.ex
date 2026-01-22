defmodule MusicListings.Parsing.VenueParsers.GreatHallParser do
  @moduledoc """
  Parser for extracing events from https://thegreathall.ca
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://thegreathall.ca/calendar/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".tgh-future"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    class_text_containing_event_id = Selectors.class(event, css(".tgh-future"))
    event_regex = ~r/event-\d+/

    [event_id] = Regex.run(event_regex, class_text_containing_event_id)
    String.replace(event_id, "-", "_")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".tgh-e-title"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".tgh-e-title"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week_string, month_string, day_string, year_string] =
      event
      |> Selectors.text(css(".tgh-e-date"))
      |> String.split()

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
         |> Selectors.text(css(".tgh-e-time"))
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
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".tgh-event-button a"))
  end
end
