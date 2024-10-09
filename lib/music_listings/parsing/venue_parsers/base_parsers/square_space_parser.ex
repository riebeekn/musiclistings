defmodule MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceParser do
  @moduledoc """
  Base parser for square space sites
  """

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  def retrieve_events_fun do
    fn url -> Req.get(url) end
  end

  def events(body) do
    Selectors.all_matches(body, css("article.eventlist-event"))
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event) do
    event
    |> Selectors.text(css(".eventlist-title-link"))
    |> String.replace("POETRY JAZZ CAFE PRESENTS: ", "")
    |> String.replace("POETRY PRESENTS: ", "")
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event
    |> Selectors.match_one(css("li.eventlist-meta-item time.event-date"))
    |> Selectors.attr("datetime")
    |> Date.from_iso8601!()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event
    |> Selectors.text(css("li.eventlist-meta-item time.event-time-12hr"))
    |> ParseHelpers.build_time_from_time_string()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(_event) do
    nil
  end

  def details_url(event, source_url) do
    event_url = Selectors.url(event, css(".eventlist-title a"))
    "#{source_url}#{event_url}"
  end
end
