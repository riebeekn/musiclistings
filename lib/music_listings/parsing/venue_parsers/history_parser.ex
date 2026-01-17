defmodule MusicListings.Parsing.VenueParsers.HistoryParser do
  @moduledoc """
  Parser for extracing events from https://www.historytoronto.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.CarbonhouseParser

  @impl true
  def source_url, do: "https://www.historytoronto.com/events/events_ajax/0?per_page=60"

  @impl true
  defdelegate retrieve_events_fun, to: CarbonhouseParser

  @impl true
  defdelegate events(body), to: CarbonhouseParser

  @impl true
  defdelegate next_page_url(body, current_url), to: CarbonhouseParser

  @impl true
  defdelegate event_id(event), to: CarbonhouseParser

  @impl true
  defdelegate ignored_event_id(event), to: CarbonhouseParser

  @impl true
  defdelegate event_title(event), to: CarbonhouseParser

  @impl true
  defdelegate performers(event), to: CarbonhouseParser

  @impl true
  defdelegate event_date(event), to: CarbonhouseParser

  @impl true
  defdelegate additional_dates(event), to: CarbonhouseParser

  @impl true
  defdelegate event_time(event), to: CarbonhouseParser

  @impl true
  defdelegate price(event), to: CarbonhouseParser

  @impl true
  defdelegate age_restriction(event), to: CarbonhouseParser

  @impl true
  defdelegate ticket_url(event), to: CarbonhouseParser

  @impl true
  defdelegate details_url(event), to: CarbonhouseParser
end
