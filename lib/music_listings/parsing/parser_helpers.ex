defmodule MusicListings.Parsing.ParseHelpers do
  @moduledoc """
  Module that contains helper / common functions around parsing
  """
  import Meeseeks.CSS

  # ===========================================================================
  # Id helpers
  # ===========================================================================
  @spec build_id_from_title_and_date(title :: String.t(), date :: Date.t()) :: String.t()
  def build_id_from_title_and_date(title, date) do
    space_and_punct_regex = ~r/[[:punct:]\s]+/
    slug = "#{title}_#{date}"

    space_and_punct_regex
    |> Regex.replace(slug, "_")
    |> String.downcase()
  end

  def convert_event_time_string_to_time(time_string) do
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

  def maybe_adjust_for_pm(hour, minute_string) do
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

  def convert_age_restriction_string_to_enum(age_restriction_string) do
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

  def convert_month_string_to_number(month_string) do
    month_string
    |> String.downcase()
    |> month_string_to_number()
  end

  defp month_string_to_number("january"), do: 1
  defp month_string_to_number("jan"), do: 1
  defp month_string_to_number("february"), do: 2
  defp month_string_to_number("feb"), do: 2
  defp month_string_to_number("march"), do: 3
  defp month_string_to_number("mar"), do: 3
  defp month_string_to_number("april"), do: 4
  defp month_string_to_number("apr"), do: 4
  defp month_string_to_number("may"), do: 5
  defp month_string_to_number("june"), do: 6
  defp month_string_to_number("jun"), do: 6
  defp month_string_to_number("july"), do: 7
  defp month_string_to_number("jul"), do: 7
  defp month_string_to_number("august"), do: 8
  defp month_string_to_number("aug"), do: 8
  defp month_string_to_number("september"), do: 9
  defp month_string_to_number("sep"), do: 9
  defp month_string_to_number("october"), do: 10
  defp month_string_to_number("oct"), do: 10
  defp month_string_to_number("november"), do: 11
  defp month_string_to_number("nov"), do: 11
  defp month_string_to_number("december"), do: 12
  defp month_string_to_number("dec"), do: 12

  def extract_event_id_from_ticketmaster_url(ticket_url) do
    regex = ~r/event\/(?<event_id>[^?\/]+)(?:\?|$)/
    Regex.named_captures(regex, ticket_url)["event_id"]
  end

  @doc """
  A couple of sites use the following format for the date:
  <span class="m-date__day">31</span>
  <span class="m-date__month"> July </span>
  <span class="m-date__year"> 2024 </span>
  """
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
end
