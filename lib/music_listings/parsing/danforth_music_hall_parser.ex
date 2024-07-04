defmodule MusicListings.Parsing.DanforthMusicHallParser do
  import Meeseeks.CSS
  import Meeseeks.XPath

  alias MusicListings.Parsing.Parser
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @behaviour Parser

  def source_url, do: "https://thedanforth.com/"

  def venue_name, do: "Danforth Music Hall"

  def event_selector(body) do
    Meeseeks.all(body, css(".event-block"))
  end

  def next_page_url(body) do
    Meeseeks.one(body, css(".nav-next a"))
  end

  def event_id(event) do
    event
    |> Meeseeks.one(css(".event-block"))
    |> Meeseeks.Result.attr("id")
  end

  def event_title(event) do
    event
    |> Meeseeks.one(css(".entry-title"))
    |> Meeseeks.Result.text()
  end

  def performers(event) do
    artists =
      event
      |> Meeseeks.all(css(".artistname"))
      |> Enum.map(&Meeseeks.Result.text/1)

    if artists == [] do
      %Performers{headliner: "", openers: ""}
    else
      [headliner | openers] = artists
      %Performers{headliner: headliner, openers: openers}
    end
  end

  def event_date(event) do
    event
    |> Meeseeks.one(css(".listingdate"))
    |> Meeseeks.Result.attr("class")
    |> String.split()
    |> Enum.at(1)
    |> String.to_integer()
    |> DateTime.from_unix!()
    |> DateTime.to_date()
  end

  def event_time(event) do
    event
    |> Meeseeks.one(xpath("//div[@class='doors']/following-sibling::div[1]"))
    |> Meeseeks.Result.text()
    |> IO.inspect(label: "time text")
    |> String.split("-")
    |> Enum.at(0)
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

  # TODO: should we have helper methods for common stuff like downcase / trime etc?
  def price(event) do
    price_string =
      event
      |> Meeseeks.one(xpath("//div[@class='tickets']/following-sibling::div[1]"))
      |> Meeseeks.Result.text()
      |> String.downcase()
      |> String.replace("(plus service fees)", "")
      |> String.replace("$", "")

    variable_price? = String.contains?(price_string, "+")

    [lo_string, hi_string] =
      price_string
      |> String.replace("+", "")
      |> String.split("-")
      |> case do
        [lo, hi] -> [lo, hi]
        [single_price] -> [single_price, single_price]
      end

    # TODO: maybe put some of the logic into a .new function
    %Price{
      lo: Decimal.new(lo_string |> String.trim()),
      hi: Decimal.new(hi_string |> String.trim()),
      format: price_format(lo_string, hi_string, variable_price?)
    }
  end

  defp price_format(_, _, true), do: :variable
  defp price_format(lo, hi, _) when lo == hi, do: :fixed
  defp price_format(_, _, _), do: :range

  def age_restriction(event) do
    time_age =
      event
      |> Meeseeks.one(xpath("//div[@class='doors']/following-sibling::div[1]"))
      |> Meeseeks.Result.text()

    if time_age == "TBD" do
      :tbd
    else
      time_age
      |> String.split("-")
      |> Enum.at(1)
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
  end

  def ticket_url(event) do
    event
    |> Meeseeks.one(css(".ticketlink a"))
    |> Meeseeks.Result.attr("href")
  end
end
