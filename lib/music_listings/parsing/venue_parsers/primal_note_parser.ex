defmodule MusicListings.Parsing.VenueParsers.PrimalNoteParser do
  @moduledoc """
  Parser for extracing events from https://primalnote.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceParser

  @base_url "https://primalnote.com"

  @impl true
  def source_url, do: "#{@base_url}/events"

  @impl true
  defdelegate retrieve_events_fun, to: SquareSpaceParser

  @impl true
  defdelegate events(body), to: SquareSpaceParser

  @impl true
  defdelegate next_page_url(body, current_url), to: SquareSpaceParser

  @impl true
  def event_id(event) do
    SquareSpaceParser.event_id(event, "primal_note")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: SquareSpaceParser

  @impl true
  defdelegate performers(event), to: SquareSpaceParser

  @impl true
  defdelegate event_date(event), to: SquareSpaceParser

  @impl true
  defdelegate additional_dates(event), to: SquareSpaceParser

  @impl true
  defdelegate event_time(event), to: SquareSpaceParser

  @impl true
  defdelegate price(event), to: SquareSpaceParser

  @impl true
  defdelegate age_restriction(event), to: SquareSpaceParser

  @impl true
  defdelegate ticket_url(event), to: SquareSpaceParser

  @impl true
  def details_url(event) do
    SquareSpaceParser.details_url(event, @base_url)
  end
end
