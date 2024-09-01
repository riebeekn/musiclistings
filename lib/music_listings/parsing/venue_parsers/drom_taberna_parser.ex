defmodule MusicListings.Parsing.VenueParsers.DromTabernaParser do
  @moduledoc """
  Parser for extracing events from https://www.dromtaberna.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url do
    today = DateHelpers.today()

    "https://www.dromtaberna.com/api/open/GetItemsByMonth?month=#{today.month}-#{today.year}&collectionId=62c7b220c14f6e5949312039&crumb=BaGbBC9SWUozNDMxZWE4MzRjMTg5OTQ4ZjkyMGQ1NjUzZGJhYzNj"
  end

  @impl true
  def example_data_file_location, do: "test/data/drom_taberna/index.json"

  @impl true
  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  @impl true
  def next_page_url(_body, current_url) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)

    next_page_url =
      "https://www.dromtaberna.com/api/open/GetItemsByMonth?month=#{next_month.month}-#{next_month.year}&collectionId=62099f5a37eb917826df65cc&crumb=BZxZJlGW0oALYzcxZDM5MjgzOGE1NmQ0ZTcyOWY3NjdhZWFmMDVi"

    if current_url == next_page_url do
      nil
    else
      next_page_url
    end
  end

  @impl true
  def event_id(event) do
    event["id"]
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["excerpt"]
    |> Selectors.all_matches(css("p"))
    |> Selectors.text()
    |> Enum.map_join(", ", & &1)
  end

  @impl true
  def performers(_event) do
    Performers.new([])
  end

  @impl true
  def event_date(event) do
    event["startDate"]
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_date()
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(_event) do
    "https://www.dromtaberna.com/"
  end
end
