defmodule MusicListings.Parsing.VenueParsers.BurdockParser do
  @moduledoc """
  Parser for extracing events from https://burdockbrewery.com via Showpass API
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ShowpassParser

  @venue_id 17_330

  @impl true
  def source_url, do: ShowpassParser.build_source_url(@venue_id)

  @impl true
  defdelegate retrieve_events_fun, to: ShowpassParser

  @impl true
  defdelegate events(body), to: ShowpassParser

  @impl true
  defdelegate next_page_url(body, current_url), to: ShowpassParser

  # Burdock events were originally stored keyed on the numeric Showpass id
  # rather than the slug, so keep that to avoid re-inserting existing events
  @impl true
  def event_id(event) do
    event["id"]
    |> to_string()
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

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
