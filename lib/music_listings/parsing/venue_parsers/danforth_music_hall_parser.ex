defmodule MusicListings.Parsing.VenueParsers.DanforthMusicHallParser do
  @moduledoc """
  Parser for extracing events from https://thedanforth.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS
  import Meeseeks.XPath

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://thedanforth.com"

  @impl true
  def example_data_file_location, do: "test/data/danforth_music_hall/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".event-block"))
  end

  @impl true
  def next_page_url(body) do
    Selectors.url(body, css(".nav-next a"))
  end

  @impl true
  def event_id(event) do
    Selectors.id(event, css(".event-block"))
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".entry-title"))
  end

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".artistname"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> Selectors.class(css(".listingdate"))
    |> String.split()
    |> Enum.at(1)
    |> String.to_integer()
    |> DateTime.from_unix!()
    |> DateTime.to_date()
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(xpath("//div[@class='doors']/following-sibling::div[1]"))
    |> String.split("-")
    |> Enum.at(0)
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(event) do
    event
    |> Selectors.text(xpath("//div[@class='tickets']/following-sibling::div[1]"))
    |> ParseHelpers.convert_price_string_to_price()
  end

  @impl true
  def age_restriction(event) do
    time_age = Selectors.text(event, xpath("//div[@class='doors']/following-sibling::div[1]"))

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
    Selectors.url(event, css(".ticketlink a"))
  end
end
