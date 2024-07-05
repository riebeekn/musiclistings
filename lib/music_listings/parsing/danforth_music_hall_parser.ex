defmodule MusicListings.Parsing.DanforthMusicHallParser do
  @behaviour MusicListings.Parsing.Parser

  import Meeseeks.CSS
  import Meeseeks.XPath

  alias MusicListings.Parsing.Parser

  def source_url, do: "https://thedanforth.com/"

  def venue_name, do: "Danforth Music Hall"

  def event_selector(body) do
    Parser.event_selector(body, ".event-block")
  end

  def next_page_url(body) do
    Parser.next_page_url(body, ".nav-next a")
  end

  def event_id(event) do
    Parser.event_id(event, ".event-block")
  end

  def event_title(event) do
    Parser.event_title(event, ".entry-title")
  end

  def performers(event) do
    Parser.performers(event, ".artistname")
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
    |> String.split("-")
    |> Enum.at(0)
    |> Parser.convert_event_time_string_to_time()
  end

  def price(event) do
    event
    |> Meeseeks.one(xpath("//div[@class='tickets']/following-sibling::div[1]"))
    |> Meeseeks.Result.text()
    |> Parser.convert_price_string_to_price()
  end

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
      |> Parser.convert_age_restriction_string_to_enum()
    end
  end

  def ticket_url(event) do
    Parser.ticket_url(event, ".ticketlink a")
  end
end
