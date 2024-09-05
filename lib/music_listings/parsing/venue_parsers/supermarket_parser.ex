defmodule MusicListings.Parsing.VenueParsers.SupermarketParser do
  @moduledoc """
  Parser for extracing events from https://www.supermarketto.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers

  alias MusicListings.Parsing.VenueParsers.BaseParsers.ElfsightParser

  @impl true
  def source_url,
    do:
      "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Fwww.supermarketto.ca%2Fevents&w=03901524-2610-4337-ae40-0bb8e9f87389"

  @impl true
  def example_data_file_location, do: "test/data/supermarket/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["data"]["widgets"]["03901524-2610-4337-ae40-0bb8e9f87389"]["data"]["settings"]["events"]
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
    id = event["id"]

    "https://www.supermarketto.ca/events#calendar-03901524-2610-4337-ae40-0bb8e9f87389-event-#{id}"
  end
end
