defmodule MusicListings.Parsing.VenueParsers.BaseParsers.WixParser do
  @moduledoc """
  Base parser for wix sites
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  # Wix Events registration types.  Only an EXTERNAL event carries a vendor url;
  # a TICKETS event is sold by Wix itself, on the event's own page.  RSVP (1) and
  # NO_REGISTRATION (4) events have nothing to buy - a venue that takes cash at
  # the door is the latter, and correctly has no ticket url at all.
  @external_registration 3
  @wix_ticketing_registration 2

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event) do
    event["id"]
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event) do
    event["title"]
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    case scheduling_config(event) do
      %{"scheduleTbd" => true, "scheduleTbdMessage" => message} ->
        {date, _time} = parse_schedule_tbd_message(message)
        date

      %{"startDate" => start_date} ->
        start_date
        |> parse_utc_datetime()
        |> DateHelpers.to_eastern_date()
    end
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    case scheduling_config(event) do
      %{"scheduleTbd" => true, "scheduleTbdMessage" => message} ->
        {_date, time} = parse_schedule_tbd_message(message)
        time

      %{"startDate" => start_date} ->
        start_date
        |> parse_utc_datetime()
        |> DateHelpers.to_eastern_time()
    end
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event, event_page_base_url) do
    case registration_type(event) do
      @external_registration -> event["registration"]["external"]["registration"]
      @wix_ticketing_registration -> event_page_url(event, event_page_base_url)
      _nothing_to_buy -> nil
    end
  end

  # Each event has a page of its own on the venue's site, which is where a Wix
  # ticketed event is bought.  The event carries no absolute url of its own, and
  # the route the venue publishes those pages under is theirs to choose - some
  # use /events, others /event-details - so the caller supplies the whole base.
  def event_page_url(event, event_page_base_url) do
    case event["slug"] do
      nil -> nil
      "" -> nil
      slug -> "#{event_page_base_url}/#{slug}"
    end
  end

  def details_url(_event) do
    nil
  end

  defp registration_type(event) do
    get_in(event, ["registration", "type"])
  end

  defp scheduling_config(event) do
    get_in(event, ["scheduling", "config"]) || %{}
  end

  defp parse_utc_datetime(start_date) do
    {:ok, utc_datetime, _offset} = DateTime.from_iso8601(start_date)
    utc_datetime
  end

  # A Wix event whose schedule is "TBD" carries no startDate at all - only a
  # free text message the venue typed in.  Some venues use that for the actual
  # date, e.g. "Sept 15,2026. 9:00 PM", so pull the date (and time, when it's
  # there) out of the message rather than dropping the event.
  @schedule_tbd_message_regex ~r/^\s*(?<month>[a-z]+)\.?\s+(?<day>\d{1,2})\s*,?\s*(?<year>\d{4})(?:[.,\s]+(?<time>\d{1,2}(?::\d{2})?\s*[ap]\.?m\.?))?/i

  defp parse_schedule_tbd_message(message) do
    case Regex.named_captures(@schedule_tbd_message_regex, message) do
      %{"month" => month, "day" => day, "year" => year, "time" => time} ->
        {:ok, date} = ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
        {date, ParseHelpers.time_from_time_string(time)}

      nil ->
        raise ArgumentError, "unparseable Wix scheduleTbdMessage: #{inspect(message)}"
    end
  end
end
