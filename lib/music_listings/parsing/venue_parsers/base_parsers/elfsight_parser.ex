defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser do
  @moduledoc """
  Base parser for elfsite json data
  """

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    event["id"]
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event) do
    event["name"]
    |> String.trim()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    if is_map(event["start"]) do
      [year_string, month_string, day_string] = event["start"]["date"] |> String.split("-")

      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
    else
      nil
    end
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    if is_map(event["start"]) do
      ParseHelpers.time_string_to_time(event["start"]["time"])
    else
      nil
    end
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

  def details_url(event) do
    event["buttonLink"]["rawValue"]
    |> case do
      "" -> nil
      details_url -> details_url
    end
  end
end
