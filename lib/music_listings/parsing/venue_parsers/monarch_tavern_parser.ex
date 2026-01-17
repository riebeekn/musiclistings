defmodule MusicListings.Parsing.VenueParsers.MonarchTavernParser do
  @moduledoc """
  Parser for extracing events from https://www.themonarchtavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.TockifyParser

  @venue_name "monarch_tavern"
  @calendar_name "monarchtavern"

  @impl true
  def source_url do
    TockifyParser.build_source_url(@calendar_name)
  end

  @impl true
  defdelegate retrieve_events_fun, to: TockifyParser

  @impl true
  defdelegate events(body), to: TockifyParser

  @impl true
  defdelegate next_page_url(body, current_url), to: TockifyParser

  @impl true
  def event_id(event) do
    TockifyParser.event_id_from_datetime(@venue_name, event)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: TockifyParser

  @impl true
  defdelegate performers(event), to: TockifyParser

  @impl true
  defdelegate event_date(event), to: TockifyParser

  @impl true
  defdelegate additional_dates(event), to: TockifyParser

  @impl true
  defdelegate event_time(event), to: TockifyParser

  @impl true
  defdelegate price(event), to: TockifyParser

  @impl true
  defdelegate age_restriction(event), to: TockifyParser

  @impl true
  defdelegate ticket_url(event), to: TockifyParser

  @impl true
  defdelegate details_url(event), to: TockifyParser
end
