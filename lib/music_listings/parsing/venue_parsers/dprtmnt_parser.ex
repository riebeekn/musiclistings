defmodule MusicListings.Parsing.VenueParsers.DprtmntParser do
  @moduledoc """
  Parser for extracing events from https://dprtmnt.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser

  @impl true
  def source_url,
    do:
      "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Fdprtmnt.com%2Fevents%2F&w=a969d3fe-6f22-4cb5-a7f1-1b03dad77e15"

  @impl true
  defdelegate retrieve_events_fun, to: ElfsightParser

  @impl true
  def example_data_file_location, do: "test/data/rebel/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["data"]["widgets"]["a969d3fe-6f22-4cb5-a7f1-1b03dad77e15"]["data"]["settings"]["events"]
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
  defdelegate details_url(event), to: ElfsightParser
end
