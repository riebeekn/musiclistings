defmodule MusicListings.Parsing.VenueParsers.StandardTimeParser do
  @moduledoc """
  Parser for extracting events from https://standardtime.to/club
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.DiceParser

  @impl true
  def source_url, do: DiceParser.build_source_url("Standard Time")

  @impl true
  defdelegate retrieve_events_fun, to: DiceParser

  @impl true
  defdelegate events(body), to: DiceParser

  @impl true
  defdelegate next_page_url(body, current_url), to: DiceParser

  @impl true
  def event_id(event), do: DiceParser.event_id(event, "standard_time")

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  defdelegate event_title(event), to: DiceParser

  @impl true
  defdelegate performers(event), to: DiceParser

  @impl true
  defdelegate event_date(event), to: DiceParser

  @impl true
  defdelegate additional_dates(event), to: DiceParser

  @impl true
  defdelegate event_time(event), to: DiceParser

  @impl true
  defdelegate price(event), to: DiceParser

  @impl true
  defdelegate age_restriction(event), to: DiceParser

  @impl true
  defdelegate ticket_url(event), to: DiceParser

  @impl true
  defdelegate details_url(event), to: DiceParser
end
