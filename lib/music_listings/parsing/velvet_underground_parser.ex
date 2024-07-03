defmodule MusicListings.Parsing.VelvetUndergroundParser do
  import Meeseeks.CSS

  def url, do: "https://thevelvet.ca/events/"

  def venue_name, do: "Velvet Underground"

  def event_selector(body) do
    Meeseeks.all(body, css(".event-block"))
  end

  def next_page_selector(body) do
    Meeseeks.one(body, css(".nav-previous a"))
  end

  def event_id_selector(event) do
    event
    |> Meeseeks.one(css(".event-block"))
    |> Meeseeks.Result.attr("id")
  end

  def event_title_selector(event) do
    event
    |> Meeseeks.one(css(".event-title"))
    |> Meeseeks.Result.text()
  end

  def artists_selector(event) do
    event
    |> Meeseeks.all(css(".event-artist-name"))
    |> Enum.map(&Meeseeks.Result.text/1)
  end

  def date_selector(event) do
    date_string =
      event
      |> Meeseeks.one(css(".event-block"))
      |> Meeseeks.Result.attr("data-event-date")

    year = String.slice(date_string, 0..3) |> String.to_integer()
    month = String.slice(date_string, 4..5) |> String.to_integer()
    day = String.slice(date_string, 6..7) |> String.to_integer()

    Date.new!(year, month, day)
  end

  def time_selector(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Ages:") end)
    |> Meeseeks.text()
    |> String.split("|")
    |> Enum.at(0)
    |> String.split(" ")
    |> Enum.at(1)
  end

  def price_selector(event) do
    event
    |> Meeseeks.all(css(".event-meta"))
    |> Enum.find(fn element -> element |> Meeseeks.text() |> String.contains?("Price:") end)
    |> Meeseeks.text()
    |> case do
      nil -> "NO PRICE FOUND!"
      price -> price |> String.replace("Price: ", "")
    end
  end

  def age_selector(event) do
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

  def ticket_url_selector(event) do
    event
    |> Meeseeks.one(css(".event-ticket-link"))
    |> Meeseeks.Result.attr("href")
  end
end
