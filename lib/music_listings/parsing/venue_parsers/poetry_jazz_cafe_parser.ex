defmodule MusicListings.Parsing.VenueParsers.PoetryJazzCafeParser do
  @moduledoc """
  Parser for extracing events from https://www.poetryjazzcafe.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.poetryjazzcafe.com/livemusic"

  @impl true
  def example_data_file_location, do: "test/data/poetry_jazz_cafe/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css("article.eventlist-event"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
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
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".eventlist-title-link"))
    |> String.replace("POETRY JAZZ CAFE PRESENTS: ", "")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> Selectors.match_one(css("li.eventlist-meta-item time.event-date"))
    |> Selectors.attr("datetime")
    |> Date.from_iso8601!()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css("li.eventlist-meta-item time.event-time-12hr"))
    |> ParseHelpers.time_string_to_time()
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
    event_url = Selectors.url(event, css(".eventlist-title a"))
    "https://www.poetryjazzcafe.com#{event_url}"
  end
end
