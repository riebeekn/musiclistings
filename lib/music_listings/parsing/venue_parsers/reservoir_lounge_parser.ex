defmodule MusicListings.Parsing.VenueParsers.ReservoirLoungeParser do
  @moduledoc """
  Parser for extracing events from https://www.reservoirlounge.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @base_url "https://www.reservoirlounge.com"

  @impl true
  def source_url, do: "#{@base_url}/live-shows"

  @impl true
  defdelegate retrieve_events_fun, to: WixParser

  @impl true
  def events(body) do
    json =
      body
      |> Selectors.match_one(css("script[type=\"application/json\"]#wix-warmup-data"))
      |> Selectors.data()
      |> Jason.decode!()

    json["appsWarmupData"]["140603ad-af8d-84a5-2c80-a0f60cb47351"]["widgetcomp-j2hh8cwh"][
      "events"
    ]["events"]
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
  def ticket_url(event), do: WixParser.ticket_url(event, @base_url)

  @impl true
  defdelegate details_url(event), to: WixParser
end
