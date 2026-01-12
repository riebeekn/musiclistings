defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ToLiveParser do
  @moduledoc """
  Parser for extracing events from https://www.tolive.com
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  def retrieve_events_fun do
    fn url ->
      headers = [
        {"accept", "application/json, text/plain, */*"},
        {"authorization", "Bearer 6-Q_VzBlEPeEgD0gyS_c9s7a6N_0597J7RukeSb2hfA"}
      ]

      HttpClient.get(url, headers)
    end
  end

  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["items"]
    |> Enum.reject(
      &(&1["fields"]["eventStatus"] == "Cancelled" || &1["fields"]["label1"] == "Cancelled" ||
          &1["fields"]["label1"] == "Postponed" || is_nil(&1["fields"]["dateTime"]))
    )
  end

  def next_page_url(_body, _current_url) do
    nil
  end

  def event_id(event, venue_name) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime(venue_name, date, time)
  end

  def event_title(event) do
    event["fields"]["billingName"]
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    date_string = ParseHelpers.add_seconds_to_datetime_string(event["fields"]["dateTime"])
    {:ok, datetime, _offset} = DateTime.from_iso8601(date_string)
    DateHelpers.to_eastern_date(datetime)
  end

  def additional_dates(event) do
    end_date_string = event["fields"]["eventEndDateTime"]

    if end_date_string do
      start_date_string = ParseHelpers.add_seconds_to_datetime_string(event["fields"]["dateTime"])
      {:ok, start_date, _offset} = DateTime.from_iso8601(start_date_string)
      est_start_date = DateHelpers.to_eastern_date(start_date)

      end_date_string = ParseHelpers.add_seconds_to_datetime_string(end_date_string)
      {:ok, end_date, _offset} = DateTime.from_iso8601(end_date_string)
      est_end_date = DateHelpers.to_eastern_date(end_date)

      # Guard against invalid date ranges (e.g., API data has wrong year)
      if Date.compare(est_end_date, est_start_date) == :gt do
        [_opening_date | remaining_dates] =
          Date.range(est_start_date, est_end_date) |> Enum.to_list()

        remaining_dates
      else
        []
      end
    else
      []
    end
  end

  def event_time(event) do
    date_string = ParseHelpers.add_seconds_to_datetime_string(event["fields"]["dateTime"])
    {:ok, datetime, _offset} = DateTime.from_iso8601(date_string)
    DateHelpers.to_eastern_time(datetime)
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event["fields"]["ctaLabelUrl1"]
    |> case do
      nil -> nil
      ticket_url -> String.replace(ticket_url, "External:", "")
    end
  end

  def details_url(event) do
    slug = event["fields"]["id"] |> String.replace(" ", "-")
    "https://tolive.com/Event-Details-Page/reference/#{slug}"
  end
end
