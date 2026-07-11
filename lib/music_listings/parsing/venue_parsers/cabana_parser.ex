defmodule MusicListings.Parsing.VenueParsers.CabanaParser do
  @moduledoc """
  Parser for extracing events from https://cabanatoronto.com

  Events are a WordPress custom post type rendered by Elementor. The page has no
  event ld+json and the `/wp-json/wp/v2/events` API only exposes the post's
  publish date (not the event date), so the event cards are parsed directly.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://cabanatoronto.com"

  @impl true
  def source_url, do: "#{@base_url}/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".e-loop-item"))
    # The page renders its first couple of events a second time in a separate
    # Elementor loop, so the same post can appear more than once.
    |> Enum.uniq_by(&event_id/1)
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page - all events are on the events page
    nil
  end

  @impl true
  def event_id(event) do
    post_id =
      event
      |> Selectors.attr("class")
      |> then(&Regex.run(~r/post-(\d+)/, &1 || ""))
      |> case do
        [_match, post_id] -> post_id
        _no_match -> nil
      end

    "cabana_#{post_id}"
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css("h2.elementor-heading-title"))
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    # Cabana renders the date without a year (ie. "Saturday, August 22")
    event
    |> Selectors.text(css("div.elementor-heading-title"))
    |> ParseHelpers.parse_day_month_day_string()
    |> case do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(_event) do
    # no times are listed on the events page
    nil
  end

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event) do
    event
    |> Selectors.all_matches(css("a.elementor-button"))
    |> Enum.find(&(Selectors.text(&1) |> String.trim() == "Buy Tickets"))
    |> case do
      nil -> nil
      button -> Selectors.attr(button, "href")
    end
  end

  @impl true
  def details_url(_event) do
    # the event cards do not link to a per-event page
    nil
  end
end
