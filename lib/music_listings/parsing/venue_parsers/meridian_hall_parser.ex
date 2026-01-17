defmodule MusicListings.Parsing.VenueParsers.MeridianHallParser do
  @moduledoc """
  Parser for extracing events from https://www.tolive.com/Meridian-Hall-Events
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ToLiveParser

  @impl true
  def source_url,
    do:
      "https://cdn.contentful.com/spaces/nmxu5kj1b6ch/environments/master/entries?metadata.tags.sys.id%5Ball%5D=genreConcerts%2CmeridianHall&locale=en-US&include=1&limit=1000&order=-sys.createdAt"

  @impl true
  defdelegate retrieve_events_fun, to: ToLiveParser

  @impl true
  defdelegate events(body), to: ToLiveParser

  @impl true
  defdelegate next_page_url(body, current_url), to: ToLiveParser

  @impl true
  def event_id(event) do
    ToLiveParser.event_id(event, "meridian_hall")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: ToLiveParser

  @impl true
  defdelegate performers(event), to: ToLiveParser

  @impl true
  defdelegate event_date(event), to: ToLiveParser

  @impl true
  defdelegate additional_dates(event), to: ToLiveParser

  @impl true
  defdelegate event_time(event), to: ToLiveParser

  @impl true
  defdelegate price(event), to: ToLiveParser

  @impl true
  defdelegate age_restriction(event), to: ToLiveParser

  @impl true
  defdelegate ticket_url(event), to: ToLiveParser

  @impl true
  defdelegate details_url(event), to: ToLiveParser
end
