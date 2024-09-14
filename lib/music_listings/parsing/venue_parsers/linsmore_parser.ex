defmodule MusicListings.Parsing.VenueParsers.LinsmoreParser do
  @moduledoc """
  Parser for extracing events from https://www.linsmoretavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.linsmoretavern.com/event-calendar/"

  @impl true
  def example_data_file_location, do: "test/data/linsmore/index.html"

  @impl true
  def events(body) do
    # this is a bit of a horror show...
    # in the future maybe clean this up
    script_content =
      body
      |> Selectors.match_one(css(".entry-content script"))
      |> Meeseeks.data()

    regex_1 = ~r/events:\s*\[(.*)\]/s

    javascript_string =
      Regex.run(regex_1, script_content, capture: :all_but_first)
      |> List.first()

    regex_2 = ~r/(?=\{ title:)/

    javascript_string
    |> String.split(regex_2, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> List.flatten()
    |> Enum.map(fn content ->
      content
      |> String.replace(~r/(\w+):\s*'(.*?[^\\])'/, "\"\\1\": \"\\2\"")
      |> String.replace(~r/\\'/, "'")
      |> String.replace(~r/(\w+):\s*\"\"/, "\"\\1\": null")
      |> String.replace(", backgroundImage: ''", "")
      |> String.replace("},", "}")
      |> Jason.decode!()
    end)
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    event["classNames"]
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [year, month, day_and_time] = String.split(event["start"], "-")
    [day, _time] = String.split(day_and_time)

    ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    [_year, _month, day_and_time] = String.split(event["start"], "-")
    [_day, time] = String.split(day_and_time)

    ParseHelpers.build_time_from_time_string(time)
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
