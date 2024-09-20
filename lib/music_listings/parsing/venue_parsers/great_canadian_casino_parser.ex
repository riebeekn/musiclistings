defmodule MusicListings.Parsing.VenueParsers.GreatCanadianCasinoParser do
  @moduledoc """
  Parser for extracing events from https://greatcanadian.com/destinations/ontario/toronto/the-theatre/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url,
    do:
      "https://api.greatcanadian.com/wp-json/snap_widgets_api/v1/entertainment?lang=en&property=23676"

  @impl true
  def retrieve_events_fun do
    fn url -> Req.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/great_canadian_casino/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["renderd_content"]
    |> ParseHelpers.clean_html()
    |> Selectors.all_matches(css(".promo-card"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".promo-content h2"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @doc """
  Dates unfortunately take a number of different formats:
  - September 19, 2024 - September 22, 2024
  - July 15 & 16, 2025"
  - Saturday, October 19, 2024
  """
  @impl true
  def event_date(event) do
    date_string = Selectors.text(event, css(".promo-date.promo-widget-home .row .col"))

    if String.contains?(date_string, "-") do
      [start_date_string, _end_date_string] = String.split(date_string, "-")
      parse_date_string(start_date_string)
    else
      parse_date_string(date_string)
    end
  end

  @regex ~r/(?<month>\w+)\s+(?<day1>\d{1,2})(?:\s*&\s*(?<day2>\d{1,2}))?,\s+(?<year>\d{4})/
  defp parse_date_string(date_string, opts \\ []) do
    for_day = Keyword.get(opts, :for_day, :day1)

    %{
      "month" => month_string,
      "day1" => day1_string,
      "day2" => day2_string,
      "year" => year_string
    } = Regex.named_captures(@regex, date_string)

    if for_day == :day1 do
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day1_string)
    else
      if day2_string == "" do
        nil
      else
        ParseHelpers.build_date_from_year_month_day_strings(
          year_string,
          month_string,
          day2_string
        )
      end
    end
  end

  @impl true
  def additional_dates(event) do
    date_string = Selectors.text(event, css(".promo-date.promo-widget-home .row .col"))

    if String.contains?(date_string, "-") do
      [start_date_string, end_date_string] = String.split(date_string, "-")
      start_date = parse_date_string(start_date_string)
      end_date = parse_date_string(end_date_string)

      [_opening_date | remaining_dates] =
        Date.range(start_date, end_date) |> Enum.to_list()

      remaining_dates
    else
      additional_date = parse_date_string(date_string, for_day: :day2)

      if additional_date do
        [additional_date]
      else
        []
      end
    end
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
  def ticket_url(event) do
    Selectors.url(event, css(".btn.gold"))
  end

  @impl true
  def details_url(event) do
    slug = Selectors.url(event, css(".promo-img a"))
    "https://greatcanadian.com#{slug}"
  end
end
