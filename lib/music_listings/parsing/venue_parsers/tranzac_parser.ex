defmodule MusicListings.Parsing.VenueParsers.TranzacParser do
  @moduledoc """
  Parser for extracing events from https://www.tranzac.org/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url, do: "https://graphql.datocms.com/"

  @impl true
  def retrieve_events_fun do
    fn url ->
      headers = [
        {"accept", "*/*"},
        {"authorization", "Bearer d926a683ddc732a876f5e698ae6f70"},
        {"content-type", "application/json"}
      ]

      query = """
      query EventsQuery($today: DateTime!) {
        allEvents(
          filter: {
            cancelled: { eq: false },
            private: { eq: false },
            startDate: { gte: $today }
          },
          orderBy: startDate_ASC,
          first: 100
        ) {
          id
          title
          startDate
          endDate
          slug
        }
      }
      """

      today = DateHelpers.now() |> DateTime.to_iso8601()

      body =
        %{
          query: query,
          variables: %{
            today: today
          }
        }
        |> Jason.encode!()

      HTTPoison.post(url, body, headers)
    end
  end

  @impl true
  def example_data_file_location, do: "test/data/tranzac/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)
    body["data"]["allEvents"]
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    event["slug"]
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
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["startDate"])
    DateHelpers.to_eastern_date(datetime)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(event["startDate"])
    DateHelpers.to_eastern_time(datetime)
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
  def details_url(_event) do
    "https://tranzac.org"
  end
end
