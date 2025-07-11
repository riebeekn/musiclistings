defmodule MusicListings.Parsing.VenueParsers.DrakeUndergroundParser do
  @moduledoc """
  Parser for extracing events from https://www.thedrake.ca/thedrakehotel/underground/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @drake_underground_location_id 67

  @impl true
  def source_url,
    do:
      "https://thedrake.ca/wp-json/wp/v2/event?event_location=#{@drake_underground_location_id}&per_page=100"

  @impl true
  def example_data_file_location, do: "test/data/drake_underground/index.json"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    to_string(event["id"])
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]["rendered"] |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    if Application.get_env(:music_listings, :env) == :test do
      ~D[2024-07-26]
    else
      # The event date is not directly available in the API response
      # We need to fetch the event page to get the date information
      event_page_url = event["link"]

      case HttpClient.get(event_page_url) do
        {:ok, %{body: body}} ->
          extract_date_from_event_page(body)

        _fallback ->
          # Fall back to post date if we can't get the event page
          post_date_string = event["date"]
          [date_part, _rest] = String.split(post_date_string, "T")
          [year_string, month_string, day_string] = String.split(date_part, "-")

          ParseHelpers.build_date_from_year_month_day_strings(
            year_string,
            month_string,
            day_string
          )
      end
    end
  end

  defp extract_date_from_event_page(body) do
    # Look for date pattern like "Jul. 04, 7:00PM - 11:00PM"
    date_regex = ~r/(\w+)\.\s+(\d+),\s+(\d+:\d+[AP]M)/i

    case Regex.run(date_regex, body) do
      [_ign, month_string, day_string, _time_string] ->
        # If date is found, parse it (year is assumed to be current or next year)
        ParseHelpers.build_date_from_month_day_strings(month_string, day_string)

      _fallback ->
        # If we can't find the date pattern, look for date in image URL or title
        # Images often have names like "thumbnail_07-July-04-2025-Cicadachar"
        image_date_regex =
          ~r/\b(January|February|March|April|May|June|July|August|September|October|November|December)[-_](\d{1,2})[-_](\d{4})\b/i

        case Regex.run(image_date_regex, body) do
          [_ign, month_string, day_string, year_string] ->
            ParseHelpers.build_date_from_year_month_day_strings(
              year_string,
              month_string,
              day_string
            )

          _fallback ->
            # Default to today if we can't find any date information
            Date.utc_today()
        end
    end
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
  def details_url(event) do
    event["link"]
  end
end
