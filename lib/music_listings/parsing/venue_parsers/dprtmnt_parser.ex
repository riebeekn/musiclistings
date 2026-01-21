defmodule MusicListings.Parsing.VenueParsers.DprtmntParser do
  @moduledoc """
  Parser for extracing events from https://dprtmnt.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://dprtmnt.com/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".e-loop-item"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    event
    |> Selectors.attr("class")
    |> extract_event_id_from_class()
  end

  defp extract_event_id_from_class(class_string) do
    ~r/e-loop-item-(\d+)/
    |> Regex.run(class_string)
    |> case do
      [__prefix, id] -> id
      _not_found -> nil
    end
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css("h2.elementor-heading-title"))
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> Selectors.text(css("div.elementor-heading-title"))
    |> ParseHelpers.parse_day_month_day_string()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(_event) do
    :nineteen_plus
  end

  @impl true
  def ticket_url(event) do
    event
    |> Selectors.all_matches(css("a.elementor-button"))
    |> Enum.find_value(fn link ->
      text = Selectors.text(link)

      if text && String.contains?(text, "Buy Tickets") do
        Selectors.attr(link, "href")
      end
    end)
  end

  @impl true
  def details_url(_event) do
    "https://dprtmnt.com/events/"
  end
end
