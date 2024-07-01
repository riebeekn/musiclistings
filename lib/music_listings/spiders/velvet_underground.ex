defmodule MusicListings.Spiders.VelvetUnderground do
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
    [month, day] =
      event
      |> Meeseeks.one(css(".event-date h2"))
      |> Meeseeks.Result.text()
      |> String.split(",")
      |> Enum.at(1)
      |> String.split()

    day =
      day
      |> String.replace("nd", "")
      |> String.replace("rd", "")
      |> String.replace("th", "")
      |> String.replace("st", "")
      |> String.to_integer()

    month =
      month
      |> case do
        "January" -> 1
        "February" -> 2
        "March" -> 3
        "April" -> 4
        "May" -> 5
        "June" -> 6
        "July" -> 7
        "August" -> 8
        "September" -> 9
        "October" -> 10
        "November" -> 11
        "December" -> 12
      end

    Date.new!(2024, month, day)
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
