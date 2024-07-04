defmodule MusicListings.Parsing.VelvetUndergroundParser do
  import Meeseeks.CSS

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @behaviour Parser

  def source_url, do: "https://thevelvet.ca/events/"

  def venue_name, do: "Velvet Underground"

  def event_selector(body) do
    Meeseeks.all(body, css(".event-block"))
  end

  def next_page_url(body) do
    Meeseeks.one(body, css(".nav-previous a"))
  end

  def event_id(event) do
    event
    |> Meeseeks.one(css(".event-block"))
    |> Meeseeks.Result.attr("id")
  end

  def event_title(event) do
    event
    |> Meeseeks.one(css(".event-title"))
    |> Meeseeks.Result.text()
  end

  def performers(event) do
    [headliner | openers] =
      event
      |> Meeseeks.all(css(".event-artist-name"))
      |> Enum.map(&Meeseeks.Result.text/1)

    %Performers{headliner: headliner, openers: openers}
  end

  def event_date(event) do
    date_string =
      event
      |> Meeseeks.one(css(".event-block"))
      |> Meeseeks.Result.attr("data-event-date")

    year = String.slice(date_string, 0..3) |> String.to_integer()
    month = String.slice(date_string, 4..5) |> String.to_integer()
    day = String.slice(date_string, 6..7) |> String.to_integer()

    Date.new!(year, month, day)
  end

  def event_time(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(0)
    |> String.split(" ")
    |> Enum.at(1)
    |> String.trim()
    |> String.downcase()
    |> String.split(":")
    |> case do
      [hour_string, minute_string] ->
        hour =
          String.to_integer(hour_string)
          |> maybe_adjust_for_pm(minute_string)

        minute =
          String.replace(minute_string, "pm", "")
          |> String.trim()
          |> String.to_integer()

        Time.new!(hour, minute, 0)

      _ ->
        nil
    end
  end

  defp maybe_adjust_for_pm(hour, minute_string) do
    if String.contains?(minute_string, "pm") do
      hour + 12
    else
      hour
    end
  end

  def price(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Price:") end)
    |> Meeseeks.text()
    |> case do
      nil ->
        %Price{lo: Decimal.new("0"), hi: Decimal.new("0"), format: :tbd}

      price_string ->
        price_string =
          price_string
          |> String.downcase()
          |> String.replace("(plus service fees)", "")
          |> String.replace("(plus fees)", "")
          |> String.replace("price:", "")
          |> String.replace("$", "")
          |> String.trim()
          |> IO.inspect(label: "price string")

        variable_price? = String.contains?(price_string, "+")

        [lo_string, hi_string] =
          price_string
          |> String.replace("+", "")
          |> String.split("-")
          |> case do
            [lo, hi] -> [lo, hi]
            [single_price] -> [single_price, single_price]
          end

        %Price{
          lo: Decimal.new(lo_string |> String.trim() |> String.replace("$", "")),
          hi: Decimal.new(hi_string |> String.trim() |> String.replace("$", "")),
          format: price_format(lo_string, hi_string, variable_price?)
        }
    end
  end

  defp price_format(_, _, true), do: :variable
  defp price_format(lo, hi, _) when lo == hi, do: :fixed
  defp price_format(_, _, _), do: :range

  def age_restriction(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(1)
    |> String.split(" ")
    |> Enum.at(1)
    |> case do
      "All" -> :all_ages
      "All ages" -> :all_ages
      "19+" -> :nineteen_plus
    end
  end

  def ticket_url(event) do
    event
    |> Meeseeks.one(css(".event-ticket-link"))
    |> Meeseeks.Result.attr("href")
  end
end
