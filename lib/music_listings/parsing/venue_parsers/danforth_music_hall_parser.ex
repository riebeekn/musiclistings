defmodule MusicListings.Parsing.VenueParsers.DanforthMusicHallParser do
  @moduledoc """
  Parser for extracing events from https://thedanforth.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @impl true
  def source_url, do: "https://api.livenation.com/graphql"

  @impl true
  def retrieve_events_fun do
    fn url ->
      headers = [
        {"accept", "*/*"},
        {"content-type", "application/json; charset=UTF-8"},
        {"x-api-key", "da2-jmvb5y2gjfcrrep3wzeumqwgaq"}
      ]

      query = """
      query EVENTS_PAGE($include_genres: String, $start_date_time: String, $end_date_time: String) {
        getEvents(
          filter: {exclude_status_codes: ["cancelled", "postponed"], venue_id: "KovZpa3yBe", start_date_time: $start_date_time, end_date_time: $end_date_time, include_genres: $include_genres}
          limit: 72
          offset: 0
          order: "ascending"
          sort_by: "start_date"
        ) {
          artists {
            discovery_id
            name
            genre_id
            genre
          }
          discovery_id
          event_date
          event_status_code
          event_time

          name
          url
        }
      }
      """

      body = %{
        query: query
      }

      HttpClient.post(url, body, headers)
    end
  end

  @impl true
  def example_data_file_location, do: "test/data/danforth_music_hall/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)
    body["data"]["getEvents"]
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    event["discovery_id"]
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["name"]
  end

  @impl true
  def performers(event) do
    event["artists"]
    |> Enum.map(& &1["name"])
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["event_date"]
    |> Date.from_iso8601!()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event["event_time"]
    |> Time.from_iso8601!()
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
  def ticket_url(event) do
    event["url"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
