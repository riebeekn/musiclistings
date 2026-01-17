defmodule MusicListings.Parsing.VenueParsers.BovineParser do
  @moduledoc """
  Parser for extracing events from https://www.bovinesexclub.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser

  @impl true
  def source_url,
    do:
      "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Fwww.bovinesexclub.com%2F&w=235dbcca-3a0a-4622-a874-ce1dd5f36933"

  @impl true
  defdelegate retrieve_events_fun, to: ElfsightParser

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["data"]["widgets"]["235dbcca-3a0a-4622-a874-ce1dd5f36933"]["data"]["settings"]["events"]
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: ElfsightParser

  @impl true
  defdelegate event_id(event), to: ElfsightParser

  @impl true
  defdelegate ignored_event_id(event), to: ElfsightParser

  @impl true
  defdelegate event_title(event), to: ElfsightParser

  @impl true
  defdelegate performers(event), to: ElfsightParser

  @impl true
  defdelegate event_date(event), to: ElfsightParser

  @impl true
  defdelegate additional_dates(event), to: ElfsightParser

  @impl true
  defdelegate event_time(event), to: ElfsightParser

  @impl true
  defdelegate price(event), to: ElfsightParser

  @impl true
  defdelegate age_restriction(event), to: ElfsightParser

  @impl true
  defdelegate ticket_url(event), to: ElfsightParser

  @impl true
  def details_url(event) do
    "https://www.bovinesexclub.com/#calendar-235dbcca-3a0a-4622-a874-ce1dd5f36933-event-#{event["id"]}"
  end
end
