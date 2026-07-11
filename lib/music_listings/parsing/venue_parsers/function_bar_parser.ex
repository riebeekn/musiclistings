defmodule MusicListings.Parsing.VenueParsers.FunctionBarParser do
  @moduledoc """
  Parser for extracting events from https://www.functionbar.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceJsonParser

  @base_url "https://www.functionbar.ca"
  @collection_id "6756432299a26d16dca81cc2"
  @crumb ""

  @impl true
  def source_url do
    SquareSpaceJsonParser.source_url(@base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate retrieve_events_fun, to: SquareSpaceJsonParser

  @impl true
  defdelegate events(body), to: SquareSpaceJsonParser

  @impl true
  def next_page_url(_body, current_url) do
    SquareSpaceJsonParser.next_page_url(current_url, @base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate event_id(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate ignored_event_id(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate event_title(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate performers(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate event_date(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate additional_dates(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate event_time(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate price(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate age_restriction(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate ticket_url(event), to: SquareSpaceJsonParser

  @impl true
  # Function Bar's events collection lives at /live-music (not /events), so the
  # base parser's details_url would 404 - use the item's own fullUrl instead.
  def details_url(event) do
    @base_url <> event["fullUrl"]
  end
end
