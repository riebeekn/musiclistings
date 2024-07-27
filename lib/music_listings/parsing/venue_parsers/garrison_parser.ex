defmodule MusicListings.Parsing.VenueParsers.GarrisonParser do
  @moduledoc """
  Parser for extracing events from http://www.garrisontoronto.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "http://www.garrisontoronto.com/listings.html"

  @impl true
  def example_data_file_location, do: "test/data/garrison/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css("#calendar_wrap"))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    # combine date and title
    event_title = event |> event_title() |> String.downcase() |> String.replace(" ", "")
    event_date = event |> event_date()

    "#{event_title}_#{event_date}"
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css("#calendar_info_headliner"))
  end

  @impl true
  def performers(event) do
    openers =
      event
      |> Meeseeks.one(css("#calendar_info_support"))
      |> Meeseeks.one(css("a"))
      |> Meeseeks.html()
      |> String.replace(~r/<\/?a[^>]*>/, "")
      |> String.split("<br />")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    ([event_title(event)] ++ openers)
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    # get the year from the image
    calendar_img_src =
      event
      |> Meeseeks.one(css("#calendar_image img"))
      |> Meeseeks.Result.attr("src")

    regex = ~r/\/(?<year>\d{4})(?:\s|-)/

    %{"year" => year_string} =
      Regex.named_captures(regex, calendar_img_src)

    year = String.to_integer(year_string)

    # get the day and month from the calendar date div
    [_week_day_string, month_string, day_string] =
      event
      |> Meeseeks.one(css("#calendar_date"))
      |> Meeseeks.html()
      |> String.split("<br />")
      |> Enum.map(&String.replace(&1, ~r/<.*?>/, ""))
      |> Enum.map(&String.replace(&1, ~r/\s+/, ""))
      |> Enum.map(&String.downcase/1)

    day = day_string |> String.replace("o", "0") |> String.to_integer()
    month = ParseHelpers.convert_month_string_to_number(month_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    time_string =
      event
      |> Meeseeks.one(css("#calendar_info_support"))
      |> Meeseeks.one(css("span.calendar_info_doors_cover"))
      |> Meeseeks.text()

    regex = ~r/(?:(\d{1,2}):?(\d{2})?:?([APM]{2})?)/
    [_full, hour_string, minute_string, ampm] = Regex.run(regex, time_string)

    hour = String.to_integer(hour_string)
    twenty_four_hour = if ampm == "PM", do: hour + 12, else: hour
    minute = minute_from_string(minute_string)
    Time.new!(twenty_four_hour, minute, 0)
  end

  defp minute_from_string(""), do: 0
  defp minute_from_string(minute_string), do: String.to_integer(minute_string)

  @impl true
  def price(event) do
    maybe_price_string =
      event
      |> Meeseeks.one(css("#calendar_info_support"))
      |> Meeseeks.one(css("span.calendar_info_doors_cover"))
      |> Meeseeks.text()
      |> String.split()
      |> Enum.at(1)

    if String.contains?(maybe_price_string, "$") do
      ParseHelpers.convert_price_string_to_price(maybe_price_string)
    else
      ParseHelpers.convert_price_string_to_price(nil)
    end
  end

  @impl true
  def age_restriction(_event) do
    :tbd
  end

  @impl true
  def ticket_url(event) do
    event
    |> Meeseeks.one(css("#calendar_info_support span.calendar_info_doors_cover a:last-of-type"))
    |> Meeseeks.attr("href")
  end
end
