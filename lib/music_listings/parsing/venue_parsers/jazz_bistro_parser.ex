defmodule MusicListings.Parsing.VenueParsers.JazzBistroParser do
  @moduledoc """
  Parser for extracing events from https://jazzbistro.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url, do: "https://jazzbistro.ca/event-calendar"

  @impl true
  def venue_name, do: "Jazz Bistro"

  @impl true
  def example_data_file_location, do: "test/data/jazz_bistro/index.html"

  @impl true
  def event_selector(body) do
    body
    |> Meeseeks.parse()
    |> Meeseeks.one(css("script[type=\"application/ld+json\"]"))
    |> Meeseeks.data()
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
    # TODO: common
    slug = "#{event_title(event)}-#{event_date(event)}"
    Regex.replace(~r/[[:punct:]\s]+/, slug, "_")
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
    ParseHelpers.convert_price_string_to_price(nil)
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    event["url"]
  end
end
