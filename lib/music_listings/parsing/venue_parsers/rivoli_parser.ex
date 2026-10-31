defmodule MusicListings.Parsing.VenueParsers.RivoliParser do
  @moduledoc """
  Parser for extracing events from https://www.rivolitoronto.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @base_url "https://www.rivolitoronto.com"
  @event_page_base_url "#{@base_url}/events"

  @impl true
  def source_url, do: "#{@base_url}/shows"

  @impl true
  defdelegate retrieve_events_fun, to: WixParser

  @impl true
  def events(body) do
    WixParser.warmup_events(body)
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: WixParser

  @impl true
  defdelegate event_id(event), to: WixParser

  @impl true
  defdelegate ignored_event_id(event), to: WixParser

  @impl true
  defdelegate event_title(event), to: WixParser

  @impl true
  defdelegate performers(event), to: WixParser

  @impl true
  defdelegate event_date(event), to: WixParser

  @impl true
  defdelegate additional_dates(event), to: WixParser

  @impl true
  defdelegate event_time(event), to: WixParser

  @impl true
  defdelegate price(event), to: WixParser

  @impl true
  defdelegate age_restriction(event), to: WixParser

  @impl true
  def ticket_url(event), do: WixParser.ticket_url(event, @event_page_base_url)

  @impl true
  defdelegate details_url(event), to: WixParser
end
