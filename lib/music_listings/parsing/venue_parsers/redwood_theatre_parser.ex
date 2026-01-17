defmodule MusicListings.Parsing.VenueParsers.RedwoodTheatreParser do
  @moduledoc """
  Parser for extracting events from https://www.theredwoodtheatre.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @impl true
  def source_url, do: "https://www.theredwoodtheatre.com/"

  @impl true
  defdelegate retrieve_events_fun, to: WixParser

  @impl true
  def events(body) do
    json =
      body
      |> Selectors.match_one(css("script[type=\"application/json\"]#wix-warmup-data"))
      |> Selectors.data()
      |> Jason.decode!()

    json["appsWarmupData"]["140603ad-af8d-84a5-2c80-a0f60cb47351"]["widgetcomp-m1qup2z8"][
      "events"
    ]["events"]
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
  defdelegate ticket_url(event), to: WixParser

  @impl true
  def details_url(_event), do: "https://www.theredwoodtheatre.com/"
end
