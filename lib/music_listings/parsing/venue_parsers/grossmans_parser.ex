defmodule MusicListings.Parsing.VenueParsers.GrossmansParser do
  @moduledoc """
  Parser for extracing events from https://grossmanstavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://grossmanstavern.com/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/grossmans/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.match_one(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> case do
      nil -> []
      events -> Jason.decode!(events)
    end
  end

  @impl true
  def next_page_url(_body, current_url) do
    current_page = get_current_page_number(current_url)

    cond do
      current_url == source_url() ->
        "https://grossmanstavern.com/events/list/page/2/"

      current_page && current_page <= 3 ->
        "https://grossmanstavern.com/events/list/page/#{current_page + 1}/"

      true ->
        nil
    end
  end

  def get_current_page_number(url) do
    regex = ~r/page\/(\d+)\/?$/

    case Regex.run(regex, url) do
      [_, page_number] -> String.to_integer(page_number)
      _no_page_number -> nil
    end
  end

  @impl true
  def event_id(event) do
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date("grossmans", date)
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
    [event["name"]]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  @impl true
  def additional_dates(_event) do
    []
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
