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
    # TODO: down the road look into handling next pages with a specific format
    # i.e. this site has next pages such as https://jazzbistro.ca/event-calendar/month/2024-08/?mmyy=August%202024
    # currently we only grab the current month as there is no next page url to grab
    # maybe we could alter the next page function to take in an optional current page url?
    # then we could check the current url and increment it if is within 3 months of
    # the current month or something

    # one thing to be careful of is to not get into an infinite redirect if the
    # logic is wrong, maybe we would also pass in an incrementer to limit
    # things
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
    event["name"]
    |> String.replace("&#8217;", "'")
    |> String.replace("&#8220;", "\"")
    |> String.replace("&#8221;", "\"")
    |> String.replace("&#038;", "&")
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
  def event_end_date(_event) do
    nil
  end

  @impl true
  def event_time(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
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
