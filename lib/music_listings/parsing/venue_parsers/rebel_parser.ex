defmodule MusicListings.Parsing.VenueParsers.RebelParser do
  @moduledoc """
  Parser for extracing events from https://rebeltoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser

  @impl true
  def source_url,
    do:
      "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Frebeltoronto.com%2Fevents%2F&w=737e2434-3a70-460f-aa98-a1ec67d0b60b"

  @impl true
  defdelegate retrieve_events_fun, to: ElfsightParser

  @impl true
  def example_data_file_location, do: "test/data/rebel/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["data"]["widgets"]["737e2434-3a70-460f-aa98-a1ec67d0b60b"]["data"]["settings"]["events"]
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
