defmodule MusicListings.Parsing.VenueParsers.DromTabernaParser do
  @moduledoc """
  Parser for extracing events from https://www.dromtaberna.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://www.dromtaberna.com"

  @impl true
  def source_url, do: "#{@base_url}/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".home_events-list_item"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    event
    |> event_href()
    |> ParseHelpers.replace_punctuation_and_spaces()
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".home-events-list-artist"))
  end

  @impl true
  def performers(_event) do
    Performers.new([])
  end

  @impl true
  def event_date(event) do
    month_string = Selectors.text(event, css(".all-events_month"))
    day_string = Selectors.text(event, css(".date-large"))

    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(month_string, day_string)

    date
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    case event
         |> Selectors.text(css(".home-events_time"))
         |> ParseHelpers.build_time_from_time_string() do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  @impl true
  def price(event) do
    case Selectors.match_one(event, css(".text-block-16")) do
      nil -> Price.unknown()
      node -> node |> Selectors.text() |> Price.new()
    end
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
    "#{@base_url}#{event_href(event)}"
  end

  defp event_href(event) do
    Selectors.url(event, css("a.link-block"))
  end
end
