defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser do
  @moduledoc """
  Base parser for elfsite json data
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    event["id"]
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

    cond do
      is_nil(candidate_date) ->
        nil

      weekly_recurring?(event) and not recurrence_ended?(event) ->
        next_weekly_occurrence(candidate_date)

      true ->
        candidate_date
    end
  end

  defp next_weekly_occurrence(start_date) do
    today = DateHelpers.today()

    if Date.compare(start_date, today) != :lt do
      # The series starts today or in the future - the first occurrence is the start date
      start_date
    else
      # Calculate how many days have passed since the initial date
      days_since_initial = Date.diff(today, start_date)

      # Determine the next upcoming occurrence (add days to reach the next week)
      days_until_next =
        case rem(days_since_initial, 7) do
          0 -> 0
          remainder -> 7 - remainder
        end

      # Calculate the next occurrence
      Date.add(today, days_until_next)
    end
  end

  defp start_date(event) do
    if is_map(event["start"]) do
      [year_string, month_string, day_string] = event["start"]["date"] |> String.split("-")

      {:ok, date} =
        ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)

      date
    else
      nil
    end
  end

  # Elfsight represents weekly recurrence two ways: the legacy "weeklyOn"
  # repeatPeriod, and the newer "custom" repeatPeriod with a weekly frequency.
  defp weekly_recurring?(event) do
    event["repeatPeriod"] == "weeklyOn" or
      (event["repeatPeriod"] == "custom" and event["repeatFrequency"] == "weekly" and
         event["repeatInterval"] in [nil, 1])
  end

  # A recurring series that ended in the past should not produce future
  # occurrences - falling through to the raw (past) start date lets the crawler
  # filter it out.
  defp recurrence_ended?(event) do
    with "onDate" <- event["repeatEnds"],
         %{"date" => date_string} when is_binary(date_string) <- event["repeatEndsDate"],
         [year_string, month_string, day_string] <- String.split(date_string, "-"),
         {:ok, end_date} <-
           ParseHelpers.build_date_from_year_month_day_strings(
             year_string,
             month_string,
             day_string
           ) do
      Date.compare(end_date, DateHelpers.today()) == :lt
    else
      _no_end_date -> false
    end
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    if is_map(event["start"]) do
      case ParseHelpers.build_time_from_time_string(event["start"]["time"]) do
        {:ok, time} -> time
        {:error, _reason} -> nil
      end
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
