defmodule MusicListings.Parsing.VenueParsers.JazzBistroParser do
  @moduledoc """
  Parser for extracing events from https://jazzbistro.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://jazzbistro.ca/event-calendar"

  @impl true
  def example_data_file_location, do: "test/data/jazz_bistro/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.match_one(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> Jason.decode!()
    |> Enum.filter(&(&1["@type"] == "Event"))
  end

  @impl true
  def next_page_url(_body) do
    # TODO: think if there is a way to handle specific next pages
    # as https://jazzbistro.ca/event-calendar/month/2024-08/?mmyy=August%202024
    # works with this site... the way we currently have it set up it will
    # only grab the current month
    # maybe this function takes in an optional current page url?

    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def event_title(event) do
    event["name"]
    |> String.replace("&#8217;", "'")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def event_time(_event) do
    nil
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
    event["url"]
  end
end
