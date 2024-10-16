defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser do
  @moduledoc """
  Base parser for elfsite json data
  """

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  def retrieve_events_fun do
    fn url -> HTTPoison.get(url) end
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    if weekly_event?(event) do
      title = event_title(event)
      date = event_date(event)

      ParseHelpers.build_id_from_title_and_date(title, date)
    else
      event["id"]
    end
  end

  defp weekly_event?(event) do
    event["repeatPeriod"] == "weeklyOn"
  end

  def ignored_event_id(event) do
    event["id"]
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
    candidate_date = start_date(event)

    if weekly_event?(event) do
      {date_for_this_week, _date_for_next_week} = next_two_occurrences(candidate_date)
      date_for_this_week
    else
      candidate_date
    end
  end

  defp start_date(event) do
    if is_map(event["start"]) do
      [year_string, month_string, day_string] = event["start"]["date"] |> String.split("-")
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
    else
      nil
    end
  end

  defp next_two_occurrences(initial_date) do
    today = DateHelpers.today()

    # Calculate how many days have passed since the initial date
    days_since_initial = Date.diff(today, initial_date)

    # Determine the next upcoming occurrence (add days to reach the next week)
    days_until_next =
      if rem(days_since_initial, 7) == 0 do
        0
      else
        7 - rem(days_since_initial, 7)
      end

    # Calculate the next two weekly occurrences
    week_1_date = Date.add(today, days_until_next)
    week_2_date = Date.add(week_1_date, 7)

    {week_1_date, week_2_date}
  end

  def additional_dates(event) do
    if weekly_event?(event) do
      start_date = start_date(event)
      {_date_for_this_week, date_for_next_week} = next_two_occurrences(start_date)
      [date_for_next_week]
    else
      []
    end
  end

  def event_time(event) do
    if is_map(event["start"]) do
      ParseHelpers.build_time_from_time_string(event["start"]["time"])
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
