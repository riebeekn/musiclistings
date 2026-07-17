defmodule MusicListings.Parsing.VenueParsers.LowBarParser do
  @moduledoc """
  Parser for extracting events from https://ma.to/venue/l0w_bar (Low Bar)
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.MatoParser

  @username "l0w_bar"
  @id_prefix "low_bar"

  @impl true
  def source_url, do: MatoParser.build_source_url(@username)

  @impl true
  def retrieve_events_fun, do: MatoParser.retrieve_events_fun(@username)

  @impl true
  def events(body), do: MatoParser.events(body, @username)

  @impl true
  defdelegate next_page_url(body, current_url), to: MatoParser

  @impl true
  def event_id(event), do: MatoParser.event_id(event, @id_prefix)

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  defdelegate event_title(event), to: MatoParser

  @impl true
  defdelegate performers(event), to: MatoParser

  @impl true
  defdelegate event_date(event), to: MatoParser

  @impl true
  defdelegate additional_dates(event), to: MatoParser

  @impl true
  defdelegate event_time(event), to: MatoParser

  @impl true
  defdelegate price(event), to: MatoParser

  @impl true
  defdelegate age_restriction(event), to: MatoParser

  @impl true
  defdelegate ticket_url(event), to: MatoParser

  @impl true
  defdelegate details_url(event), to: MatoParser
end
