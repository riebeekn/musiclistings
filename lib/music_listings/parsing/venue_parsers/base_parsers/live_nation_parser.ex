defmodule MusicListings.Parsing.VenueParsers.BaseParsers.LiveNationParser do
  @moduledoc """
  Base parser for Live Nation sites
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  def source_url, do: "https://api.livenation.com/graphql"

  def retrieve_events_fun(live_nation_venue_id) do
    fn url ->
      headers = [
        {"accept", "*/*"},
        {"content-type", "application/json; charset=UTF-8"},
        {"x-api-key", "da2-jmvb5y2gjfcrrep3wzeumqwgaq"}
      ]

      query = """
      query EVENTS_PAGE($venue_id: String!, $include_genres: String, $start_date_time: String, $end_date_time: String) {
        getEvents(
          filter: {exclude_status_codes: ["cancelled", "postponed"], venue_id: $venue_id, start_date_time: $start_date_time, end_date_time: $end_date_time, include_genres: $include_genres}
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

      variables = %{
        venue_id: live_nation_venue_id
      }

      body = %{
        query: query,
        variables: variables
      }

      HttpClient.post(url, body, headers)
    end
  end

  def events(body) do
    body = ParseHelpers.maybe_decode!(body)
    body["data"]["getEvents"]
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    event["discovery_id"]
  end

  def event_title(event) do
    event["name"]
  end

  def performers(event) do
    event["artists"]
    |> Enum.map(& &1["name"])
    |> Performers.new()
  end

  def event_date(event) do
    event["event_date"]
    |> Date.from_iso8601!()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event["event_time"]
    |> Time.from_iso8601!()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event["url"]
  end

  def details_url(_event) do
    nil
  end
end
