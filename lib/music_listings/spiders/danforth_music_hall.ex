defmodule MusicListings.Spiders.DanforthMusicHall do
  import Meeseeks.CSS
  import Meeseeks.XPath

  def url, do: "https://thedanforth.com/"

  def venue_name, do: "Danforth Music Hall"

  def event_selector(body) do
    Meeseeks.all(body, css(".event-block"))
  end

  def next_page_selector(body) do
    Meeseeks.one(body, css(".nav-next a"))
  end

  def event_id_selector(event) do
    event
    |> Meeseeks.one(css(".event-block"))
    |> Meeseeks.Result.attr("id")
  end

  def event_title_selector(event) do
    event
    |> Meeseeks.one(css(".entry-title"))
    |> Meeseeks.Result.text()
  end

  def artists_selector(event) do
    artists =
      event
      |> Meeseeks.all(css(".artistname"))
      |> Enum.map(&Meeseeks.Result.text/1)

    if artists == [] do
      ["", ""]
    else
      artists
    end
  end

  def date_selector(event) do
    [_weekday, month, day] =
      event
      |> Meeseeks.one(css(".listingdate"))
      |> Meeseeks.Result.text()
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
    |> Meeseeks.one(xpath("//div[@class='doors']/following-sibling::div[1]"))
    |> Meeseeks.Result.text()
    |> String.split("-")
    |> Enum.at(0)
    |> String.trim()
  end

  def price_selector(event) do
    event
    |> Meeseeks.one(xpath("//div[@class='tickets']/following-sibling::div[1]"))
    |> Meeseeks.Result.text()
  end

  def age_selector(event) do
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

  def ticket_url_selector(event) do
    event
    |> Meeseeks.one(css(".ticketlink a"))
    |> Meeseeks.Result.attr("href")
  end
end
