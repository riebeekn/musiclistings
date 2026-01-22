defmodule MusicListings.Parsing.VenueParsers.BaseParsers.BgGarrisonParser do
  @moduledoc """
  Base parser for BabyG/Garrison
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    body
    |> Selectors.all_matches(css("#calendar_wrap"))
    |> Enum.reject(&(event_title(&1) == "4am LAST CALL"))
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event, venue_name) do
    date = event_date(event)

    ParseHelpers.build_id_from_venue_and_date(venue_name, date)
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
    date_parts = split_event_date_into_parts(event)

    {:ok, date} =
      cond do
        # Range: THURSDAY OCTOBER 02 - SATURDAY OCTOBER 04
        date_range?(date_parts) ->
          [_ignore_1, month1, day1, _ignore_2, _ignore_3, _ignore_4, _ignore_5] = date_parts
          ParseHelpers.build_date_from_month_day_strings(month1, day1)

        # Standard: THURSDAY OCTOBER 02
        single_date?(date_parts) ->
          [_weekday, month, day] = date_parts
          ParseHelpers.build_date_from_month_day_strings(month, day)

        true ->
          raise "Unrecognized date format: #{inspect(date_parts)}"
      end

    date
  end

  def additional_dates(event) do
    date_parts = split_event_date_into_parts(event)

    if date_range?(date_parts) do
      parse_additional_dates(date_parts)
    else
      []
    end
  end

  defp parse_additional_dates(date_parts) do
    [_wday1, month1, day1, "-", _wday2, month2, day2] = date_parts

    {start_day, _remainder} = Integer.parse(day1)
    {end_day, _remainder} = Integer.parse(day2)

    start_day..end_day
    # skip the first day
    |> Enum.drop(1)
    |> Enum.map(fn day ->
      m = if month1 != month2, do: month2, else: month1
      {:ok, date} = ParseHelpers.build_date_from_month_day_strings(m, Integer.to_string(day))
      date
    end)
  end

  defp date_range?(date_parts), do: Enum.count(date_parts) >= 7
  defp single_date?(date_parts), do: Enum.count(date_parts) == 3

  defp split_event_date_into_parts(event) do
    event
    |> Selectors.text(css("#calendar_date"))
    |> String.replace(~r/\s+/, " ")
    |> String.upcase()
    |> String.split(" ", trim: true)
    |> Enum.map(&normalize_day_string/1)
  end

  defp normalize_day_string(str) do
    # Fix common OCR-ish typo: "o2" → "02"
    str
    |> String.replace(~r/\Ao(\d)\z/i, "0\\1")
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
