defmodule MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParser do
  @moduledoc """
  Helper module for parsing dates for arraymusic
  """
  alias MusicListings.Parsing.ParseHelpers

  defstruct [:date, :additional_dates]

  @spec parse_dates(String.t(), String.t()) :: %__MODULE__{}
  def parse_dates(event_title, raw_date_time_string) do
    cond do
      String.contains?(raw_date_time_string, "•") && String.contains?(event_title, "|") ->
        parse_multi_date_format(event_title, raw_date_time_string)

      String.contains?(raw_date_time_string, "•") ->
        parse_multi_date_format_year_in_first_date(raw_date_time_string)

      String.contains?(raw_date_time_string, ",") ->
        parse_single_date_format(raw_date_time_string)

      true ->
        %__MODULE__{date: nil, additional_dates: []}
    end
  end

  def parse_multi_date_format(event_title, raw_date_time_string) do
    [year_1_string, year_2_string] =
      event_title
      |> String.split()
      |> List.last()
      |> String.split("|")

    year_1 = String.to_integer(year_1_string) + 2_000
    year_2 = String.to_integer(year_2_string) + 2_000

    [raw_date_string, _time] = String.split(raw_date_time_string, "@")
    date_strings = raw_date_string |> String.split("•") |> Enum.map(&String.trim/1)

    dates =
      Enum.reduce(date_strings, {year_1, []}, fn date_string, {current_year, acc} ->
        [month, day] = String.split(date_string)
        year = if month == "Jan", do: year_2, else: current_year
        date = ParseHelpers.build_date_from_year_month_day_strings("#{year}", month, day)
        {year, [date | acc]}
      end)
      |> elem(1)
      |> Enum.reverse()

    [first_date | rest] = dates
    %__MODULE__{date: first_date, additional_dates: rest}
  end

  defp parse_multi_date_format_year_in_first_date(raw_date_time_string) do
    [raw_date_string, _time] = String.split(raw_date_time_string, "@")

    [first_date_string | rest] =
      raw_date_string
      |> String.split("•")
      |> Enum.map(&(&1 |> String.replace(",", "") |> String.trim()))

    [month, day, year] = String.split(first_date_string)

    first_date = ParseHelpers.build_date_from_year_month_day_strings(year, month, day)

    additional_dates =
      Enum.reduce(rest, [], fn month_day_string, acc ->
        [month, day] = String.split(month_day_string)
        date = ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
        [date | acc]
      end)
      |> Enum.reverse()

    %__MODULE__{date: first_date, additional_dates: additional_dates}
  end

  def parse_single_date_format(raw_date_time_string) do
    [month, day, year | _rest] = String.split(raw_date_time_string)

    %__MODULE__{
      date: ParseHelpers.build_date_from_year_month_day_strings(year, month, day),
      additional_dates: []
    }
  end
end
