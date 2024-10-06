defmodule MusicListings.Parsing.VenueParsers.LeesPalaceParser do
  @moduledoc """
  Parser for extracing events from https://www.leespalace.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://www.leespalace.com"

  @impl true
  def source_url, do: "#{@base_url}/events"

  @impl true
  def retrieve_events_fun do
    fn url -> Req.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/lees_palace/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".schedule-event"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event) |> String.split() |> List.first()
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".schedule-speaker-name"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".schedule-speaker-name"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week_string, month_string, day_string, year_string] =
      event
      |> Selectors.text(css(".schedule-event-time"))
      |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(event) do
    event
    |> Selectors.all_matches(css(".schedule-event-time"))
    |> Selectors.text()
    |> Enum.find(fn element -> element |> String.contains?("$") end)
    |> Price.new()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Selectors.text(css(".non"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".blb"))
  end

  @impl true
  def details_url(event) do
    event_url = Selectors.url(event, css(".schedule-speaker"))
    "#{@base_url}#{event_url}"
  end
end
