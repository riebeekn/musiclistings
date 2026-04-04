defmodule MusicListings.Parsing.VenueParsers.MasseyHallParser do
  @moduledoc """
  Parser for extracing events from https://masseyhall.mhrth.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser

  @base_url "https://masseyhall.mhrth.com"
  @impl true
  def source_url, do: "#{@base_url}/tickets/?page=1"

  @impl true
  defdelegate retrieve_events_fun, to: MhRthTdmhParser

  @impl true
  defdelegate events(body), to: MhRthTdmhParser

  @impl true
  defdelegate next_page_url(body, current_url), to: MhRthTdmhParser

  @impl true
  defdelegate event_id(event), to: MhRthTdmhParser

  @impl true
  defdelegate ignored_event_id(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_title(event), to: MhRthTdmhParser

  @impl true
  defdelegate performers(event), to: MhRthTdmhParser

  @impl true
  def event_date(event), do: MhRthTdmhParser.event_date(event, @base_url)

  @impl true
  def additional_dates(event), do: MhRthTdmhParser.additional_dates(event, @base_url)

  @impl true
  def event_time(event), do: MhRthTdmhParser.event_time(event, @base_url)

  @impl true
  defdelegate price(event), to: MhRthTdmhParser

  @impl true
  defdelegate age_restriction(event), to: MhRthTdmhParser

  @impl true
  defdelegate ticket_url(event), to: MhRthTdmhParser

  @impl true
  def details_url(event) do
    details_path = MhRthTdmhParser.details_url(event)
    "#{@base_url}#{details_path}"
  end
end
