defmodule MusicListings.Parsing.VenueParsers.RoyThomsonHallParser do
  @moduledoc """
  Parser for extracing events from https://roythomsonhall.mhrth.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser

  @base_url "https://roythomsonhall.mhrth.com"
  @impl true
  def source_url, do: "#{@base_url}/tickets/?page=1"

  @impl true
  defdelegate retrieve_events_fun, to: MhRthTdmhParser

  @impl true
  def example_data_file_location, do: "test/data/roy_thomson_hall/index.html"

  @impl true
  def events(body) do
    body
    |> MhRthTdmhParser.events()
    |> Enum.reject(fn event ->
      event
      |> event_title()
      |> String.starts_with?("TIFF - ")
    end)
  end

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
  defdelegate event_date(event), to: MhRthTdmhParser

  @impl true
  defdelegate additional_dates(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_time(event), to: MhRthTdmhParser

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
