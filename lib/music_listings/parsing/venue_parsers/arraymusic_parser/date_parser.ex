defmodule MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParser do
  @moduledoc """
  Helper module for parsing dates for arraymusic

  Handles the formats used on the season at a glance page, e.g.
  - `October 6, 2026 @ 7:30 pm ET`
  - `Nov. 21, 2026 @ 7:30 pm ET`
  - `December 18 & 19, 2026`
  - `April 23 – 25, 2027`
  - `Sep 11 • Oct 9 • Jan 8 @ 8:00 pm ET` (no year)
  - `Nov 15 @ 8:00 pm ET and Nov 17 @ 3:00 pm ET` (no year)

  Dates without a year are placed in the season starting in `season_start_year`:
  July to December fall in that year, January to June in the next.
  """
  alias MusicListings.Parsing.ParseHelpers

  defstruct [:date, :additional_dates]

  @type t :: %__MODULE__{date: Date.t() | nil, additional_dates: [Date.t()]}

  @segment_regex ~r/^([[:alpha:]]+)\.?\s+(\d{1,2})(?:\s*([&–-])\s*(\d{1,2}))?$/u
  @year_regex ~r/,?\s*\b(20\d{2})\b/
  @separator_regex ~r/•|\band\b/u
  @time_regex ~r/\b(\d{1,2}(?::\d{2})?\s*(?:am|pm|noon))/i

  @spec parse_dates(String.t(), integer()) :: t()
  def parse_dates(raw_date_time_string, season_start_year) do
    date_string = normalize(raw_date_time_string)

    explicit_year =
      case Regex.run(@year_regex, date_string) do
        [_match, year] -> String.to_integer(year)
        nil -> nil
      end

    dates =
      date_string
      |> String.replace(@year_regex, "")
      |> String.split(@separator_regex)
      |> Enum.flat_map(&parse_segment(segment_date(&1), explicit_year, season_start_year))

    case dates do
      [] -> %__MODULE__{date: nil, additional_dates: []}
      [first_date | rest] -> %__MODULE__{date: first_date, additional_dates: rest}
    end
  end

  @spec parse_time(String.t()) :: Time.t() | nil
  def parse_time(raw_date_time_string) do
    case Regex.run(@time_regex, normalize(raw_date_time_string)) do
      [_match, time_string] -> ParseHelpers.time_from_time_string(time_string)
      nil -> nil
    end
  end

  defp normalize(string) do
    string
    |> String.replace("ª", "•")
    |> String.replace(" ", " ")
  end

  # Drops the segment's time, e.g. "Nov 15 @ 8:00 pm ET" -> "Nov 15"
  defp segment_date(segment) do
    segment
    |> String.split("@")
    |> List.first()
    |> String.trim()
  end

  # A segment that isn't a month and day (e.g. a time, or a month missing its day) is skipped
  defp parse_segment(segment, explicit_year, season_start_year) do
    case Regex.run(@segment_regex, segment) do
      [_match, month, day] ->
        build_dates(month, [day], explicit_year, season_start_year)

      [_match, month, day, "&", other_day] ->
        build_dates(month, [day, other_day], explicit_year, season_start_year)

      [_match, month, first_day, _dash, last_day] ->
        days = Enum.map(String.to_integer(first_day)..String.to_integer(last_day)//1, &"#{&1}")
        build_dates(month, days, explicit_year, season_start_year)

      nil ->
        []
    end
  end

  defp build_dates(month, days, explicit_year, season_start_year) do
    Enum.flat_map(days, fn day ->
      year = explicit_year || season_year(month, day, season_start_year)

      case ParseHelpers.build_date_from_year_month_day_strings("#{year}", month, day) do
        {:ok, date} -> [date]
        {:error, :invalid_date} -> []
      end
    end)
  end

  defp season_year(month, day, season_start_year) do
    # 2000 is a leap year, so any valid month/day parses
    case ParseHelpers.build_date_from_year_month_day_strings("2000", month, day) do
      {:ok, %Date{month: month_number}} when month_number < 7 -> season_start_year + 1
      _other -> season_start_year
    end
  end
end
