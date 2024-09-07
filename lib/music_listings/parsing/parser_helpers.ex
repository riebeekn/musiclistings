defmodule MusicListings.Parsing.ParseHelpers do
  @moduledoc """
  Module that contains helper / common functions around parsing
  """

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
  end

  @spec replace_punctuation_and_spaces(String.t()) :: String.t()
  def replace_punctuation_and_spaces(string) do
    space_and_punct_regex = ~r/[\p{P}\p{Z}]+/u

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
        ) :: Date.t()
  def build_date_from_year_month_day_strings(year_string, month_string, day_string) do
    day = day_string_to_integer(day_string)
    month = month_string |> clean_month_string() |> month_string_to_integer()
    year = year_string |> String.replace(",", "") |> String.trim() |> String.to_integer()

    Date.new!(year, month, day)
  end

  @doc """
  Not all sites include the year in the event date, in those cases use this
  function which pseudo intelligently determines the year
  """
  @spec build_date_from_month_day_strings(
          month_string :: String.t(),
          day_string :: String.t(),
          today :: Date.t()
        ) ::
          Date.t()
  def build_date_from_month_day_strings(month_string, day_string, today) do
    day = day_string_to_integer(day_string)
    month = month_string |> clean_month_string() |> month_string_to_integer()

    candidate_date = Date.new!(today.year, month, day)
    maybe_increment_year(candidate_date, today)
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

  defp month_string_to_integer("january"), do: 1
  defp month_string_to_integer("jan"), do: 1
  defp month_string_to_integer("01"), do: 1
  defp month_string_to_integer("february"), do: 2
  defp month_string_to_integer("feb"), do: 2
  defp month_string_to_integer("02"), do: 2
  defp month_string_to_integer("march"), do: 3
  defp month_string_to_integer("mar"), do: 3
  defp month_string_to_integer("03"), do: 3
  defp month_string_to_integer("april"), do: 4
  defp month_string_to_integer("apr"), do: 4
  defp month_string_to_integer("04"), do: 4
  defp month_string_to_integer("may"), do: 5
  defp month_string_to_integer("05"), do: 5
  defp month_string_to_integer("june"), do: 6
  defp month_string_to_integer("jun"), do: 6
  defp month_string_to_integer("06"), do: 6
  defp month_string_to_integer("july"), do: 7
  defp month_string_to_integer("jul"), do: 7
  defp month_string_to_integer("07"), do: 7
  defp month_string_to_integer("august"), do: 8
  defp month_string_to_integer("aug"), do: 8
  defp month_string_to_integer("08"), do: 8
  defp month_string_to_integer("september"), do: 9
  defp month_string_to_integer("sep"), do: 9
  defp month_string_to_integer("09"), do: 9
  defp month_string_to_integer("october"), do: 10
  defp month_string_to_integer("oct"), do: 10
  defp month_string_to_integer("10"), do: 10
  defp month_string_to_integer("november"), do: 11
  defp month_string_to_integer("nov"), do: 11
  defp month_string_to_integer("11"), do: 11
  defp month_string_to_integer("december"), do: 12
  defp month_string_to_integer("dec"), do: 12
  defp month_string_to_integer("12"), do: 12

  defp day_string_to_integer(day_string) do
    day_string
    |> String.replace(",", "")
    |> String.replace(".", "")
    |> String.replace("st", "")
    |> String.replace("nd", "")
    |> String.replace("rd", "")
    |> String.replace("th", "")
    |> String.replace("o", "")
    |> String.trim()
    |> String.to_integer()
  end

  # ===========================================================================
  # Time helpers
  # ===========================================================================
  @spec time_string_to_time(String.t()) :: Time.t()
  def time_string_to_time(time_string) do
    (time_string || "")
    |> String.replace(":PM", " pm")
    |> String.trim()
    |> String.downcase()
    |> String.split(":")
    |> case do
      [hour_string, minute_string] ->
        hour =
          hour_string
          |> String.to_integer()
          |> maybe_adjust_for_pm(minute_string)

        minute =
          minute_string
          |> String.replace("pm", "")
          |> String.replace("am", "")
          |> String.trim()
          |> String.to_integer()

        Time.new!(hour, minute, 0)

      [hour_string] ->
        hour_string
        |> String.replace("pm", "")
        |> String.replace("am", "")
        |> String.trim()
        |> Integer.parse()
        |> case do
          {hour, _remainder} ->
            hour
            |> maybe_adjust_for_pm(hour_string)
            |> Time.new!(0, 0)

          :error ->
            nil
        end

      _tbd ->
        nil
    end
  end

  @doc """
  For handling datetime strings missing seconds
  i.e convert a dt string of the format 2024-08-31T19:00
  to 2024-08-31T19:00:00-04:00
  """
  @spec add_seconds_and_offset_to_datetime_string(String.t()) :: String.t()
  def add_seconds_and_offset_to_datetime_string(dt_string), do: "#{dt_string}:00-04:00"

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
