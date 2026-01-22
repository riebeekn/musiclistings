defmodule MusicListings.Parsing.ParseHelpers do
  @moduledoc """
  Module that contains helper / common functions around parsing
  """

  alias MusicListingsUtilities.DateHelpers

  # ===========================================================================
  # General helpers
  # ===========================================================================
  @doc """
  Bit of a hack to facilitate pulling data locally... Req converts it
  to a map when pulling from www, where-as locally we just have a file
  so when pulling local we get a string and need to decode it
  """
  @spec maybe_decode!(String.t() | map()) :: term()
  def maybe_decode!(content) do
    if is_binary(content) do
      Jason.decode!(content)
    else
      content
    end
  end

  @spec strip_extra_quotes(String.t()) :: String.t()
  def strip_extra_quotes(json_string) do
    # Regular expression to find extraneous quotes
    regex = ~r/":\s*"[^"]*",\s*"/

    cleaned_json =
      Regex.replace(regex, json_string, fn match ->
        String.replace(match, ",\"", ",")
      end)

    cleaned_json
    |> String.replace(~r/,\s*([}\]])/, "\\1")
    |> String.replace(~r/""+/, "\"")
    |> String.replace(~r/,\s*"/, ", \"")
  end

  @spec replace_punctuation_and_spaces(String.t()) :: String.t()
  def replace_punctuation_and_spaces(string) do
    space_and_punct_regex = ~r/[\p{P}\p{Z}|]+/u

    Regex.replace(space_and_punct_regex, string, "_")
  end

  @spec clean_html(String.t()) :: String.t()
  def clean_html(content) do
    content
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.replace("\\\\", "\\")
    |> String.replace("\\\"", "\"")
    |> String.replace("\\n", "\n")
    |> String.replace("\\t", "\t")
    |> String.replace("\\/", "/")
  end

  @spec fix_encoding(String.t()) :: String.t()
  def fix_encoding(content) do
    content
    |> String.replace("&#8217;", "'")
    |> String.replace("&#8220;", "\"")
    |> String.replace("&#8221;", "\"")
    |> String.replace("&#038;", "&")
    |> String.replace("\\u2018", "'")
    |> String.replace("\\u2019", "'")
    |> String.replace("&amp;", "&")
    |> String.replace("&#8211;", "-")
    |> String.replace("\\u00e9", "é")
    |> String.replace("\\u00e1", "á")
  end

  # ===========================================================================
  # Id helpers
  # ===========================================================================
  @spec build_id_from_title_and_date(title :: String.t(), date :: Date.t()) :: String.t()
  def build_id_from_title_and_date(title, date) do
    "#{title}_#{date}"
    |> replace_punctuation_and_spaces()
    |> String.downcase()
    |> String.replace("cancelled_", "")
    |> String.replace("rescheduled_", "")
    |> String.replace("postponed_", "")
  end

  def build_id_from_venue_and_date(venue_name, date) do
    "#{venue_name}_#{date}"
    |> replace_punctuation_and_spaces()
  end

  def build_id_from_venue_and_datetime(venue_name, date, time) do
    "#{venue_name}_#{date}_#{time}"
    |> replace_punctuation_and_spaces()
  end

  # ===========================================================================
  # Age restriction helpers
  # ===========================================================================
  @spec age_restriction_string_to_enum(nil | String.t()) ::
          :all_ages | :eighteen_plus | :nineteen_plus
  def age_restriction_string_to_enum(age_restriction_string) do
    (age_restriction_string || "")
    |> String.trim()
    |> String.downcase()
    |> case do
      "all" -> :all_ages
      "all ages" -> :all_ages
      "all ages event" -> :all_ages
      "18+" -> :eighteen_plus
      "19+" -> :nineteen_plus
      "19+ event" -> :nineteen_plus
      _fall_thru -> :unknown
    end
  end

  # ===========================================================================
  # Date helpers
  # ===========================================================================
  @spec build_date_from_year_month_day_strings(
          year_string :: String.t(),
          month_string :: String.t(),
          day_string :: String.t()
        ) :: {:ok, Date.t()} | {:error, :invalid_date}
  def build_date_from_year_month_day_strings(year_string, month_string, day_string) do
    with {:ok, day} <- day_string_to_integer(day_string),
         {:ok, month} <- month_string |> clean_month_string() |> month_string_to_integer(),
         {:ok, year} <- year_string_to_integer(year_string),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _error -> {:error, :invalid_date}
    end
  end

  @doc """
  Not all sites include the year in the event date, in those cases use this
  function which pseudo intelligently determines the year
  """
  @spec build_date_from_month_day_strings(
          month_string :: String.t(),
          day_string :: String.t()
        ) :: {:ok, Date.t()} | {:error, :invalid_date}
  def build_date_from_month_day_strings(month_string, day_string) do
    today = DateHelpers.today()

    with {:ok, day} <- day_string_to_integer(day_string),
         {:ok, month} <- month_string |> clean_month_string() |> month_string_to_integer(),
         {:ok, candidate_date} <- Date.new(today.year, month, day) do
      {:ok, maybe_increment_year(candidate_date, today)}
    else
      _error -> {:error, :invalid_date}
    end
  end

  @doc """
  Parses a date string in "Day, Month DD" format (e.g., "Friday, January 23")
  and returns a Date. The year is determined by build_date_from_month_day_strings.
  """
  @spec parse_day_month_day_string(String.t()) :: {:ok, Date.t()} | {:error, :invalid_date}
  def parse_day_month_day_string(date_string) do
    with [_day_of_week, month_day] <- date_string |> String.trim() |> String.split(", "),
         [month_string, day_string] <- String.split(month_day) do
      build_date_from_month_day_strings(month_string, day_string)
    else
      _error -> {:error, :invalid_date}
    end
  end

  defp maybe_increment_year(candidate_date, today) do
    # There is no year provided... so subtract a few days from today
    # then compare the dates if candidate event date < today increment
    # the year... this is pretty hacky, TODO: revisit in the future
    thirty_five_days_ago = Date.add(today, -35)

    if Date.before?(candidate_date, thirty_five_days_ago) do
      Date.new!(candidate_date.year + 1, candidate_date.month, candidate_date.day)
    else
      candidate_date
    end
  end

  defp clean_month_string(month_string) do
    month_string
    |> String.downcase()
    |> String.replace(".", "")
    |> String.trim()
  end

  defp month_string_to_integer("january"), do: {:ok, 1}
  defp month_string_to_integer("jan"), do: {:ok, 1}
  defp month_string_to_integer("01"), do: {:ok, 1}
  defp month_string_to_integer("february"), do: {:ok, 2}
  defp month_string_to_integer("feb"), do: {:ok, 2}
  defp month_string_to_integer("02"), do: {:ok, 2}
  defp month_string_to_integer("march"), do: {:ok, 3}
  defp month_string_to_integer("mar"), do: {:ok, 3}
  defp month_string_to_integer("03"), do: {:ok, 3}
  defp month_string_to_integer("april"), do: {:ok, 4}
  defp month_string_to_integer("apr"), do: {:ok, 4}
  defp month_string_to_integer("04"), do: {:ok, 4}
  defp month_string_to_integer("may"), do: {:ok, 5}
  defp month_string_to_integer("05"), do: {:ok, 5}
  defp month_string_to_integer("june"), do: {:ok, 6}
  defp month_string_to_integer("jun"), do: {:ok, 6}
  defp month_string_to_integer("06"), do: {:ok, 6}
  defp month_string_to_integer("july"), do: {:ok, 7}
  defp month_string_to_integer("jul"), do: {:ok, 7}
  defp month_string_to_integer("07"), do: {:ok, 7}
  defp month_string_to_integer("august"), do: {:ok, 8}
  defp month_string_to_integer("aug"), do: {:ok, 8}
  defp month_string_to_integer("08"), do: {:ok, 8}
  defp month_string_to_integer("september"), do: {:ok, 9}
  defp month_string_to_integer("sep"), do: {:ok, 9}
  defp month_string_to_integer("09"), do: {:ok, 9}
  defp month_string_to_integer("october"), do: {:ok, 10}
  defp month_string_to_integer("oct"), do: {:ok, 10}
  defp month_string_to_integer("10"), do: {:ok, 10}
  defp month_string_to_integer("november"), do: {:ok, 11}
  defp month_string_to_integer("nov"), do: {:ok, 11}
  defp month_string_to_integer("11"), do: {:ok, 11}
  defp month_string_to_integer("december"), do: {:ok, 12}
  defp month_string_to_integer("dec"), do: {:ok, 12}
  defp month_string_to_integer("12"), do: {:ok, 12}
  defp month_string_to_integer(_month_string), do: {:error, :invalid_month}

  defp day_string_to_integer(day_string) do
    result =
      day_string
      |> String.replace(",", "")
      |> String.replace(".", "")
      |> String.replace("st", "")
      |> String.replace("nd", "")
      |> String.replace("rd", "")
      |> String.replace("th", "")
      |> String.replace("o", "")
      |> String.trim()
      |> Integer.parse()

    case result do
      {day, _remainder} -> {:ok, day}
      :error -> {:error, :invalid_day}
    end
  end

  defp year_string_to_integer(year_string) do
    result =
      year_string
      |> String.replace(",", "")
      |> String.trim()
      |> Integer.parse()

    case result do
      {year, _remainder} -> {:ok, year}
      :error -> {:error, :invalid_year}
    end
  end

  # ===========================================================================
  # Time helpers
  # ===========================================================================
  @spec build_time_from_time_string(String.t() | nil) :: {:ok, Time.t()} | {:error, :invalid_time}
  def build_time_from_time_string(nil), do: {:error, :invalid_time}

  def build_time_from_time_string(time_string) do
    result =
      time_string
      |> String.replace("EST", "")
      |> String.replace("EDT", "")
      |> String.replace(":PM", " pm")
      |> String.replace("p.m.", "pm")
      |> String.trim()
      |> String.downcase()
      |> String.split(":")
      |> case do
        [hour_string, minute_string] ->
          with {hour, _remainder} <- Integer.parse(hour_string),
               minute_cleaned =
                 minute_string
                 |> String.replace("pm", "")
                 |> String.replace("am", "")
                 |> String.trim(),
               {minute, _remainder} <- Integer.parse(minute_cleaned) do
            hour = maybe_adjust_for_pm(hour, minute_string)
            Time.new(hour, minute, 0)
          else
            _error -> {:error, :invalid_time}
          end

        [hour_string] ->
          hour_string
          |> String.replace("pm", "")
          |> String.replace("am", "")
          |> String.trim()
          |> Integer.parse()
          |> case do
            {hour, _remainder} ->
              hour = maybe_adjust_for_pm(hour, hour_string)
              Time.new(hour, 0, 0)

            :error ->
              {:error, :invalid_time}
          end

        _other ->
          {:error, :invalid_time}
      end

    case result do
      {:ok, time} -> {:ok, time}
      _error -> {:error, :invalid_time}
    end
  end

  @doc """
  For handling datetime strings missing seconds and offset
  i.e convert a dt string of the format 2024-08-31T19:00
  to 2024-08-31T19:00:00-04:00
  """
  @spec add_seconds_and_offset_to_datetime_string(String.t()) :: String.t()
  def add_seconds_and_offset_to_datetime_string(dt_string), do: "#{dt_string}:00-04:00"

  @doc """
  For handling datetime strings missing seconds
  i.e. convert a dt string of the format 2024-08-31T19:00-04:00
  to 2024-08-31T19:00:00-04:00
  """
  @spec add_seconds_to_datetime_string(String.t()) :: String.t()
  def add_seconds_to_datetime_string(dt_string) do
    [date, time_with_offset] = String.split(dt_string, "T")
    [time, offset] = String.split(time_with_offset, "-")
    time_with_seconds = "#{time}:00"
    "#{date}T#{time_with_seconds}-#{offset}"
  end

  defp maybe_adjust_for_pm(hour, minute_string) do
    if String.contains?(minute_string, "pm") do
      if hour == 12 do
        12
      else
        hour + 12
      end
    else
      hour
    end
  end
end
