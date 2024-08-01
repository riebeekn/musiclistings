defmodule MusicListings.Parsing.VenueParsers.OperaHouseParser do
  @moduledoc """
  Parser for extracing events from https://theoperahousetoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://theoperahousetoronto.com/calendar"

  @impl true
  def example_data_file_location, do: "test/data/opera_house/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".item_landing"))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def event_title(event) do
    main_title = Selectors.text(event, css(".info_landing h2"))

    supplementary_title =
      event
      |> Selectors.all_matches(css(".info_landing h3"))
      |> Selectors.text()

    "#{main_title} #{supplementary_title}"
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    day_string = Selectors.text(event, css(".date_number_listing"))
    month_string = Selectors.text(event, css(".date_landing h6:last-of-type"))

    ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css(".info_landing h5:nth-of-type(2)"))
    |> String.replace("Show: ", "")
    |> ParseHelpers.time_string_to_time()
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Selectors.text(css(".info_landing h5:last-of-type"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".ticket_landing a"))
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".no_deco"))
  end
end