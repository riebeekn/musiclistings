defmodule MusicListings.Parsing.VenueParsers.QueenElizabthTheatreParser do
  @moduledoc """
  Parser for extracing events from https://www.queenelizabeththeatre.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url,
    do:
      "https://gateway.admitone.com/embed/live-events?venueId=5f2c38d9b49c22464830180a&order=asc"

  @impl true
  def example_data_file_location, do: "test/data/queen_elizabeth_theatre/index.json"

  @impl true
  def events(body) do
    # bit of a hack to facilitate pulling data locally... Req converts it
    # to a map when pulling from www, where-as locally we just have a file
    # so when pulling local we get a string and need to decode! it
    body = if is_binary(body), do: Jason.decode!(body), else: body

    body["events"]
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title_slug = event |> event_title() |> String.replace(" ", "")
    "#{title_slug}-#{event_date(event)}"
  end

  @impl true
  def event_title(event) do
    event["title"]
  end

  @impl true
  def performers(event) do
    [event["title"]]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [month_string, day_string, year_string] = String.split(event["event_date"])

    year = String.to_integer(year_string)
    month = ParseHelpers.convert_month_string_to_number(month_string)

    # TODO: common
    day =
      day_string
      |> String.trim()
      |> String.replace("st", "")
      |> String.replace("nd", "")
      |> String.replace("rd", "")
      |> String.replace("th", "")
      |> String.replace(",", "")
      |> String.to_integer()

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    event["doors"]
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(event) do
    event["price_range"]
    |> ParseHelpers.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    event["age_limit"]
    |> ParseHelpers.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    event["url"]
  end
end
