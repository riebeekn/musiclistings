defmodule MusicListings.Parsing.VenueParsers.GrossmansParser do
  @moduledoc """
  Parser for extracing events from https://grossmanstavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.WordpressParser

  @impl true
  def source_url, do: "https://grossmanstavern.com/events/"

  @impl true
  defdelegate retrieve_events_fun, to: WordpressParser

  @impl true
  defdelegate events(body), to: WordpressParser

  @impl true
  defdelegate next_page_url(body, current_url), to: WordpressParser

  @impl true
  def event_id(event) do
    WordpressParser.event_id(event, "grossmans")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: WordpressParser

  @impl true
  defdelegate performers(event), to: WordpressParser

  @impl true
  defdelegate event_date(event), to: WordpressParser

  @impl true
  defdelegate additional_dates(event), to: WordpressParser

  @impl true
  defdelegate event_time(event), to: WordpressParser

  @impl true
  defdelegate price(event), to: WordpressParser

  @impl true
  defdelegate age_restriction(event), to: WordpressParser

  @impl true
  defdelegate ticket_url(event), to: WordpressParser

  @impl true
  defdelegate details_url(event), to: WordpressParser
end
