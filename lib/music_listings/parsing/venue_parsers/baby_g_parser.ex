defmodule MusicListings.Parsing.VenueParsers.BabyGParser do
  @moduledoc """
  Parser for extracing events from http://thebabyg.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers

  @impl true
  def source_url, do: "http://thebabyg.com"

  @impl true
  def example_data_file_location, do: "test/data/baby_g/index.html"

  @impl true
  def event_selector(body) do
    ParseHelpers.event_selector(body, "#calendar_wrap")
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
    ParseHelpers.event_title(event, "#calendar_info_headliner")
  end

  @openers_time_price_regex ~r/^(.*)\s+(\d{1,2}:[APM]{2})\s+\$([\d.]+)(?:\s+\w+)?$/

  @impl true
  def performers(event) do
    openers_time_price_string =
      event
      |> Meeseeks.one(css("#calendar_info_support"))
      |> Meeseeks.text()

    [_original_string, openers, _time, _price] =
      Regex.run(@openers_time_price_regex, openers_time_price_string)

    ([event_title(event)] ++ [openers])
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    calendar_img_src =
      event
      |> Meeseeks.one(css("#calendar_image img"))
      |> Meeseeks.Result.attr("src")

    regex = ~r/images\/\d{4}\/(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})-/

    %{"year" => year_string, "month" => month_string, "day" => day_string} =
      Regex.named_captures(regex, calendar_img_src)

    day = String.to_integer(day_string)
    month = String.to_integer(month_string)
    year = String.to_integer(year_string)

    Date.new!(year, month, day)
  end

  @impl true
  def event_time(event) do
    openers_time_price_string =
      event
      |> Meeseeks.one(css("#calendar_info_support"))
      |> Meeseeks.text()

    [_original_string, _openers, time, _price] =
      Regex.run(@openers_time_price_regex, openers_time_price_string)

    hour = time |> String.replace(":PM", "") |> String.to_integer()

    Time.new!(hour + 12, 0, 0)
  end

  @impl true
  def price(event) do
    openers_time_price_string =
      event
      |> Meeseeks.one(css("#calendar_info_support"))
      |> Meeseeks.text()

    [_original_string, _openers, _time, price] =
      Regex.run(@openers_time_price_regex, openers_time_price_string)

    ParseHelpers.convert_price_string_to_price(price)
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
