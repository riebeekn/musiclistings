defmodule MusicListings.Parsing.ParseHelpers do
  @moduledoc """
  Module that contains helper / common functions around parsing
  """
  import Meeseeks.CSS

  # ===========================================================================
  # General helpers
  # ===========================================================================
  # TODO: add spec
  def maybe_decode!(content) do
    # bit of a hack to facilitate pulling data locally... Req converts it
    # to a map when pulling from www, where-as locally we just have a file
    # so when pulling local we get a string and need to decode it
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

  @doc """
  For handling datetime strings missing seconds
  i.e convert a dt string of the format 2024-08-31T19:00
  to 2024-08-31T19:00:00-04:00
  """
  @spec add_seconds_and_offset_to_datetime_string(String.t()) :: String.t()
  def add_seconds_and_offset_to_datetime_string(dt_string), do: "#{dt_string}:00-04:00"

  # ===========================================================================
  # Id helpers
  # ===========================================================================
  @spec build_id_from_title_and_date(title :: String.t(), date :: Date.t()) :: String.t()
  def build_id_from_title_and_date(title, date) do
    space_and_punct_regex = ~r/[\p{P}\p{Z}]+/u
    slug = "#{title}_#{date}"

    space_and_punct_regex
    |> Regex.replace(slug, "_")
    |> String.downcase()
  end

  # TODO: get rid of this
  def extract_event_id_from_ticketmaster_url(ticket_url) do
    regex = ~r/event\/(?<event_id>[^?\/]+)(?:\?|$)/
    Regex.named_captures(regex, ticket_url)["event_id"]
  end

  # ===========================================================================
  # Age restriction helpers
  # ===========================================================================
  def age_restriction_string_to_enum(age_restriction_string) do
    age_restriction_string
    |> String.trim()
    |> String.downcase()
    |> case do
      "all" -> :all_ages
      "all ages" -> :all_ages
      "all ages event" -> :all_ages
      "18+" -> :eighteen_plus
      "19+" -> :nineteen_plus
      "19+ event" -> :nineteen_plus
    end
  end

  # ===========================================================================
  # Date helpers
  # ===========================================================================
  # TODO: might be able to dump this? as we might be able to just call into
  # build_date_from_year_month_day_strings everywhere?
  def convert_month_string_to_number(month_string) do
    month_string
    |> String.downcase()
    |> month_string_to_number()
  end

  defp month_string_to_number("january"), do: 1
  defp month_string_to_number("jan"), do: 1
  defp month_string_to_number("01"), do: 1
  defp month_string_to_number("february"), do: 2
  defp month_string_to_number("feb"), do: 2
  defp month_string_to_number("02"), do: 2
  defp month_string_to_number("march"), do: 3
  defp month_string_to_number("mar"), do: 3
  defp month_string_to_number("03"), do: 3
  defp month_string_to_number("april"), do: 4
  defp month_string_to_number("apr"), do: 4
  defp month_string_to_number("04"), do: 4
  defp month_string_to_number("may"), do: 5
  defp month_string_to_number("05"), do: 5
  defp month_string_to_number("june"), do: 6
  defp month_string_to_number("jun"), do: 6
  defp month_string_to_number("06"), do: 6
  defp month_string_to_number("july"), do: 7
  defp month_string_to_number("jul"), do: 7
  defp month_string_to_number("07"), do: 7
  defp month_string_to_number("august"), do: 8
  defp month_string_to_number("aug"), do: 8
  defp month_string_to_number("08"), do: 8
  defp month_string_to_number("september"), do: 9
  defp month_string_to_number("sep"), do: 9
  defp month_string_to_number("09"), do: 9
  defp month_string_to_number("october"), do: 10
  defp month_string_to_number("oct"), do: 10
  defp month_string_to_number("10"), do: 10
  defp month_string_to_number("november"), do: 11
  defp month_string_to_number("nov"), do: 11
  defp month_string_to_number("11"), do: 11
  defp month_string_to_number("december"), do: 12
  defp month_string_to_number("dec"), do: 12
  defp month_string_to_number("12"), do: 12

  @doc """
  A couple of sites use the following format for the date:
  <span class="m-date__day">31</span>
  <span class="m-date__month"> July </span>
  <span class="m-date__year"> 2024 </span>
  """
  # TODO: dump this
  def extract_date_from_m__xx_format(event) do
    day_string =
      event
      |> Meeseeks.one(css(".m-date__day"))
      |> Meeseeks.text()
      |> String.trim()

    month_string =
      event
      |> Meeseeks.one(css(".m-date__month"))
      |> Meeseeks.text()
      |> String.trim()

    year_string =
      event
      |> Meeseeks.one(css(".m-date__year"))
      |> Meeseeks.text()
      |> String.replace(",", "")
      |> String.trim()

    day = String.to_integer(day_string)
    month = convert_month_string_to_number(month_string)
    year = String.to_integer(year_string)

    Date.new!(year, month, day)
  end

  @spec build_date_from_year_month_day_strings(
          year_string :: String.t(),
          month_string :: String.t(),
          day_string :: String.t()
        ) :: Date.t()
  def build_date_from_year_month_day_strings(year_string, month_string, day_string) do
    day = day_string_to_integer(day_string)
    # TODO: rename convert_month_string_to_number to month_string_to_integer
    month = convert_month_string_to_number(month_string)
    year = year_string |> String.replace(",", "") |> String.trim() |> String.to_integer()

    Date.new!(year, month, day)
  end

  @spec build_date_from_month_day_strings(month_string :: String.t(), day_string :: String.t()) ::
          Date.t()
  def build_date_from_month_day_strings(month_string, day_string) do
    day = day_string_to_integer(day_string)
    month = convert_month_string_to_number(month_string)

    today = Date.utc_today()
    candidate_date = Date.new!(today.year, month, day)
    maybe_increment_year(candidate_date, today)
  end

  defp maybe_increment_year(candidate_date, today) do
    # There is no year provided... so subtract a few days from today
    # then compare the dates if candidate show date < today increment
    # the year...
    # TODO: revisit this, is there some better way of trying to determine
    # the year of the event?
    fifteen_days_ago = Date.add(today, -15)

    if Date.before?(candidate_date, fifteen_days_ago) do
      Date.new!(candidate_date.year + 1, candidate_date.month, candidate_date.day)
    else
      candidate_date
    end
  end

  defp day_string_to_integer(day_string) do
    day_string
    |> String.replace(",", "")
    |> String.trim()
    |> String.replace("st", "")
    |> String.replace("nd", "")
    |> String.replace("rd", "")
    |> String.replace("th", "")
    |> String.to_integer()
  end

  # ===========================================================================
  # Time helpers
  # ===========================================================================
  @spec time_string_to_time(String.t()) :: Time.t()
  def time_string_to_time(time_string) do
    (time_string || "")
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
