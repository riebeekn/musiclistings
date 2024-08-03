defmodule MusicListings.Parsing.VenueParsers.BgGarrisonParser do
  @moduledoc """
  Common Parser for BabyG/Garrison
  """
  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  def events(body) do
    Selectors.all_matches(body, css("#calendar_wrap"))
  end

  def next_page_url(_body) do
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
    Selectors.text(event, css("#calendar_info_headliner"))
  end

  def performers(event) do
    openers =
      event
      |> Selectors.text(css("#calendar_info_support a"))

    headliner = event_title(event)

    ([headliner] ++ [openers])
    |> Performers.new()
  end

  def event_date(event) do
    [_day_of_week, month_string, day_string] =
      event
      |> Selectors.text(css("#calendar_date"))
      |> String.split()

    ParseHelpers.build_date_from_month_day_strings(month_string, day_string, Date.utc_today())
  end

  def event_time(_event) do
    nil
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event
    |> Selectors.match_one(css(".calendar_info_doors_cover a"))
    |> case do
      nil -> nil
      url_result -> Selectors.attr(url_result, "href")
    end
  end

  def details_url(_event) do
    nil
  end
end
