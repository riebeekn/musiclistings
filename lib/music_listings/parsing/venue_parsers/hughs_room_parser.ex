defmodule MusicListings.Parsing.VenueParsers.HughsRoomParser do
  @moduledoc """
  Parser for extracing events from https://hughsroomlive.com/ via Showpass API
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ShowpassParser

  @venue_id 5705

  @impl true
  def source_url, do: ShowpassParser.build_source_url(@venue_id)

  @impl true
  defdelegate retrieve_events_fun, to: ShowpassParser

  @impl true
  defdelegate events(body), to: ShowpassParser

  @impl true
  defdelegate next_page_url(body, current_url), to: ShowpassParser

  @impl true
  defdelegate event_id(event), to: ShowpassParser

  @impl true
  defdelegate ignored_event_id(event), to: ShowpassParser, as: :event_id

  @impl true
  defdelegate event_title(event), to: ShowpassParser

  @impl true
  defdelegate performers(event), to: ShowpassParser

  @impl true
  defdelegate event_date(event), to: ShowpassParser

  @impl true
  defdelegate additional_dates(event), to: ShowpassParser

  @impl true
  defdelegate event_time(event), to: ShowpassParser

  @impl true
  defdelegate price(event), to: ShowpassParser

  @impl true
  defdelegate age_restriction(event), to: ShowpassParser

  @impl true
  defdelegate ticket_url(event), to: ShowpassParser

  @impl true
  defdelegate details_url(event), to: ShowpassParser
end
