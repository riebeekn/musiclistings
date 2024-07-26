defmodule MusicListings.Parsing.VenueParsers.DanforthMusicHallParser do
  @moduledoc """
  Parser for extracing events from https://thedanforth.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS
  import Meeseeks.XPath

  alias MusicListings.Parsing.ParseHelpers

  @impl true
  def source_url, do: "https://thedanforth.com"

  @impl true
  def example_data_file_location, do: "test/data/danforth_music_hall/index.html"

  @impl true
  def event(body) do
    ParseHelpers.event_selector(body, ".event-block")
  end

  @impl true
  def next_page_url(body) do
    ParseHelpers.next_page_url(body, ".nav-next a")
  end

  @impl true
  def event_id(event) do
    ParseHelpers.event_id(event, ".event-block")
  end

  @impl true
  def event_title(event) do
    ParseHelpers.event_title(event, ".entry-title")
  end

  @impl true
  def performers(event) do
    ParseHelpers.performers(event, ".artistname")
  end

  @impl true
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

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.one(xpath("//div[@class='doors']/following-sibling::div[1]"))
    |> Meeseeks.text()
    |> String.split("-")
    |> Enum.at(0)
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(event) do
    event
    |> Meeseeks.one(xpath("//div[@class='tickets']/following-sibling::div[1]"))
    |> Meeseeks.text()
    |> ParseHelpers.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    time_age =
      event
      |> Meeseeks.one(xpath("//div[@class='doors']/following-sibling::div[1]"))
      |> Meeseeks.text()

    if time_age == "TBD" do
      :tbd
    else
      time_age
      |> String.split("-")
      |> Enum.at(1)
      |> ParseHelpers.convert_age_restriction_string_to_enum()
    end
  end

  @impl true
  def ticket_url(event) do
    ParseHelpers.ticket_url(event, ".ticketlink a")
  end
end
