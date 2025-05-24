defmodule MusicListings.Parsing.VenueParsers.PilotParser do
  @moduledoc """
  Parser for extracing events from https://thepilot.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.thepilot.ca/events"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/pilot/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("script[type=\"application/ld+json\"]"))
    |> Enum.flat_map(fn script ->
      case Selectors.data(script) do
        nil ->
          []

        json ->
          json
          |> remove_trailing_commas()
          |> Jason.decode()
          |> process_decoded_data()
      end
    end)
  end

  defp process_decoded_data(data) do
    data
    |> case do
      {:ok, items} when is_list(items) ->
        Enum.filter(items, &(&1["@type"] == "Event"))

      {:ok, item} when is_map(item) ->
        if item["@type"] == "Event", do: [item], else: []

      _no_events ->
        []
    end
  end

  defp remove_trailing_commas(json) do
    # Removes trailing commas before } or ]
    Regex.replace(~r/,\s*([\]}])/m, json, "\\1")
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)

    ParseHelpers.build_id_from_venue_and_date("pilot", date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["name"]
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> parse_datetime()
    |> DateTime.to_date()
  end

  defp parse_datetime(event) do
    {:ok, datetime, _offset} =
      event["startDate"]
      |> String.replace(~r/(\+|\-)(\d{2})(\d{2})$/, "\\1\\2:\\3")
      |> DateTime.from_iso8601()

    datetime
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> parse_datetime()
    |> DateTime.to_time()
    |> Map.put(:second, 0)
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
