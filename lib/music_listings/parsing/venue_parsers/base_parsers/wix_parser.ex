defmodule MusicListings.Parsing.VenueParsers.BaseParsers.WixParser do
  @moduledoc """
  Base parser for wix sites
  """
  alias MusicListings.HttpClient
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
    {:ok, utc_datetime, _offset} =
      event["scheduling"]["config"]["startDate"]
      |> DateTime.from_iso8601()

    DateHelpers.to_eastern_date(utc_datetime)
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    {:ok, utc_datetime, _offset} =
      event["scheduling"]["config"]["startDate"]
      |> DateTime.from_iso8601()

    DateHelpers.to_eastern_time(utc_datetime)
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event, base_url) do
    case registration_type(event) do
      @external_registration -> event["registration"]["external"]["registration"]
      @wix_ticketing_registration -> event_page_url(event, base_url)
      _nothing_to_buy -> nil
    end
  end

  # Each event has a page of its own on the venue's site, which is where a Wix
  # ticketed event is bought.  The event carries no absolute url of its own, so
  # the venue's base url has to be supplied.
  def event_page_url(event, base_url) do
    case event["slug"] do
      nil -> nil
      "" -> nil
      slug -> "#{base_url}/event-details/#{slug}"
    end
  end

  def details_url(_event) do
    nil
  end

  defp registration_type(event) do
    get_in(event, ["registration", "type"])
  end
end
