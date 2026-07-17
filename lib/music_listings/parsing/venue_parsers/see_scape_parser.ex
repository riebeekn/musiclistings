defmodule MusicListings.Parsing.VenueParsers.SeeScapeParser do
  @moduledoc """
  Parser for extracting events from https://ra.co/clubs/257804 (See-Scape)
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ResidentAdvisorParser

  @club_id "257804"
  @id_prefix "see_scape"

  @impl true
  def source_url, do: ResidentAdvisorParser.build_source_url(@club_id)

  @impl true
  def retrieve_events_fun, do: ResidentAdvisorParser.retrieve_events_fun(@club_id)

  @impl true
  def events(body), do: ResidentAdvisorParser.events(body, @club_id)

  @impl true
  defdelegate next_page_url(body, current_url), to: ResidentAdvisorParser

  @impl true
  def event_id(event), do: ResidentAdvisorParser.event_id(event, @id_prefix)

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  defdelegate event_title(event), to: ResidentAdvisorParser

  @impl true
  defdelegate performers(event), to: ResidentAdvisorParser

  @impl true
  defdelegate event_date(event), to: ResidentAdvisorParser

  @impl true
  defdelegate additional_dates(event), to: ResidentAdvisorParser

  @impl true
  defdelegate event_time(event), to: ResidentAdvisorParser

  @impl true
  defdelegate price(event), to: ResidentAdvisorParser

  @impl true
  defdelegate age_restriction(event), to: ResidentAdvisorParser

  @impl true
  defdelegate ticket_url(event), to: ResidentAdvisorParser

  @impl true
  defdelegate details_url(event), to: ResidentAdvisorParser
end
