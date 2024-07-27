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
    title_slug = event |> event_title() |> String.replace(" ", "")
    "#{title_slug}-#{event_date(event)}"
  end

  @impl true
  def event_title(event) do
    main_title =
      event
      |> Meeseeks.one(css(".info_landing h2"))
      |> Meeseeks.text()

    supplementary_title =
      event
      |> Meeseeks.all(css(".info_landing h3"))
      |> Enum.map(&Meeseeks.text/1)

    "#{main_title} #{supplementary_title}"
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    day_string =
      event
      |> Meeseeks.one(css(".date_number_listing"))
      |> Meeseeks.text()
      |> String.trim()

    month_string =
      event
      |> Meeseeks.one(css(".date_landing h6:last-of-type"))
      |> Meeseeks.text()
      |> String.trim()

    day = String.to_integer(day_string)
    month = ParseHelpers.convert_month_string_to_number(month_string)

    # TODO: common
    today = Date.utc_today()
    candidate_date = Date.new!(today.year, month, day)
    maybe_increment_year(candidate_date, today)
  end

  defp maybe_increment_year(candidate_date, today) do
    # There is no year provided... so subtract a few days from today
    # then compare the dates if candidate show date < today increment
    # the year...
    # TODO: revisit this, is there some better way of trying to determine
    # the year of the event?
    fifteen_days_ago = Date.add(today, -15)

    if Date.before?(candidate_date, fifteen_days_ago) do
      Date.new!(candidate_date.year + 1, candidate_date.month, candidate_date.day)
    else
      candidate_date
    end
  end

  @impl true
  def event_time(event) do
    event
    |> Meeseeks.one(css(".info_landing h5:nth-of-type(2)"))
    |> Meeseeks.text()
    |> String.replace("Show: ", "")
    |> ParseHelpers.convert_event_time_string_to_time()
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(event) do
    event
    |> Meeseeks.one(css(".info_landing h5:last-of-type"))
    |> Meeseeks.text()
    |> ParseHelpers.convert_age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    Selectors.url(event, css(".ticket_landing a"))
  end
end
