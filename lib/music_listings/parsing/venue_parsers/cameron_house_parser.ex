defmodule MusicListings.Parsing.VenueParsers.CameronHouseParser do
  @moduledoc """
  Parser for extracing events from https://www.thecameron.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @impl true
  def source_url, do: "https://www.thecameron.com/shows"

  @impl true
  defdelegate retrieve_events_fun, to: WixParser

  @impl true
  def example_data_file_location, do: "test/data/cameron_house/index.html"

  @impl true
  def events(body) do
    json =
      body
      |> Selectors.match_one(css("script[type=\"application/json\"]#wix-warmup-data"))
      |> Selectors.data()
      |> Jason.decode!()

    json["appsWarmupData"]["140603ad-af8d-84a5-2c80-a0f60cb47351"]["widgetcomp-j9ny0yyr"][
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
  defdelegate ticket_url(event), to: WixParser

  @impl true
  def details_url(_event), do: "https://www.thecameron.com/"
end
