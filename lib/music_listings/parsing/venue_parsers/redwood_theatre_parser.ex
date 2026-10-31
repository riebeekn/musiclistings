defmodule MusicListings.Parsing.VenueParsers.RedwoodTheatreParser do
  @moduledoc """
  Parser for extracting events from https://www.theredwoodtheatre.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @base_url "https://www.theredwoodtheatre.com"
  @event_page_base_url "#{@base_url}/event-details"

  @impl true
  def source_url, do: "#{@base_url}/"

  @impl true
  defdelegate retrieve_events_fun, to: WixParser

  @impl true
  def events(body) do
    WixParser.warmup_events(body)
    |> Enum.reject(&schedule_tbd?/1)
  end

  defp schedule_tbd?(event) do
    get_in(event, ["scheduling", "config", "scheduleTbd"]) == true
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: WixParser

  @impl true
  defdelegate event_id(event), to: WixParser

  @impl true
  defdelegate ignored_event_id(event), to: WixParser

  @impl true
  defdelegate event_title(event), to: WixParser

  @impl true
  defdelegate performers(event), to: WixParser

  @impl true
  defdelegate event_date(event), to: WixParser

  @impl true
  defdelegate additional_dates(event), to: WixParser

  @impl true
  defdelegate event_time(event), to: WixParser

  @impl true
  defdelegate price(event), to: WixParser

  @impl true
  defdelegate age_restriction(event), to: WixParser

  @impl true
  def ticket_url(event), do: WixParser.ticket_url(event, @event_page_base_url)

  @impl true
  def details_url(event), do: WixParser.event_page_url(event, @event_page_base_url)
end
