defmodule MusicListings.Parsing.Parser do
  @moduledoc """
  Module that defines the behaviour for a Parser and also
  contains helper / common functions around parsing
  """
  import Meeseeks.CSS
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @callback source_url() :: String.t()
  @callback venue_name() :: String.t()
  @callback example_data_file_location() :: String.t()
  @callback event_selector(String.t()) :: [Meeseeks.Result.t()] | {:error, Meeseeks.Error.t()}
  @callback next_page_url(String.t()) :: String.t() | nil
  @callback event_id(Meeseeks.Result.t()) :: String.t()
  @callback event_title(Meeseeks.Result.t()) :: String.t()
  @callback performers(Meeseeks.Result.t()) :: Performers.t()
  @callback event_date(Meeseeks.Result.t()) :: Date.t()
  @callback event_time(Meeseeks.Result.t()) :: Time.t() | nil
  @callback price(Meeseeks.Result.t()) :: Price.t()
  @callback age_restriction(Meeseeks.Result.t()) :: :all_ages | :nineteen_plus | :tbd
  @callback ticket_url(Meeseeks.Result.t()) :: String.t() | nil

  def event_selector(body, event_selector) do
    Meeseeks.all(body, css(event_selector))
  end

  def next_page_url(body, next_page_selector) do
    body
    |> Meeseeks.one(css(next_page_selector))
    |> case do
      nil -> nil
      result -> Meeseeks.Result.attr(result, "href")
    end
  end

  def event_id(%Meeseeks.Result{} = event, event_id_selector) do
    event
    |> Meeseeks.one(css(event_id_selector))
    |> Meeseeks.Result.attr("id")
  end

  def event_title(%Meeseeks.Result{} = event, event_title_selector) do
    event
    |> Meeseeks.one(css(event_title_selector))
    |> Meeseeks.text()
  end

  def performers(%Meeseeks.Result{} = event, performers_selector) do
    event
    |> Meeseeks.all(css(performers_selector))
    |> Enum.map(&Meeseeks.Result.text/1)
    |> Performers.new()
  end

  def ticket_url(%Meeseeks.Result{} = event, ticket_url_selector) do
    event
    |> Meeseeks.one(css(ticket_url_selector))
    |> Meeseeks.Result.attr("href")
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

  defdelegate convert_price_string_to_price(price_string), to: Price, as: :new

  def convert_age_restriction_string_to_enum(age_restriction_string) do
    age_restriction_string
    |> String.trim()
    |> String.downcase()
    |> case do
      "all" -> :all_ages
      "all ages" -> :all_ages
      "all ages event" -> :all_ages
      "19+" -> :nineteen_plus
      "19+ event" -> :nineteen_plus
    end
  end

  def convert_month_string_to_number("January"), do: 1
  def convert_month_string_to_number("Jan"), do: 1
  def convert_month_string_to_number("February"), do: 2
  def convert_month_string_to_number("Feb"), do: 2
  def convert_month_string_to_number("March"), do: 3
  def convert_month_string_to_number("Mar"), do: 3
  def convert_month_string_to_number("April"), do: 4
  def convert_month_string_to_number("Apr"), do: 4
  def convert_month_string_to_number("May"), do: 5
  def convert_month_string_to_number("June"), do: 6
  def convert_month_string_to_number("Jun"), do: 6
  def convert_month_string_to_number("July"), do: 7
  def convert_month_string_to_number("Jul"), do: 7
  def convert_month_string_to_number("August"), do: 8
  def convert_month_string_to_number("Aug"), do: 8
  def convert_month_string_to_number("September"), do: 9
  def convert_month_string_to_number("Sep"), do: 9
  def convert_month_string_to_number("October"), do: 10
  def convert_month_string_to_number("Oct"), do: 10
  def convert_month_string_to_number("November"), do: 11
  def convert_month_string_to_number("Nov"), do: 11
  def convert_month_string_to_number("December"), do: 12
  def convert_month_string_to_number("Dec"), do: 12

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
