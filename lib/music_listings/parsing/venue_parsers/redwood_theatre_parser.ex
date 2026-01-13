defmodule MusicListings.Parsing.VenueParsers.RedwoodTheatreParser do
  @moduledoc """
  Parser for extracting events from https://www.theredwoodtheatre.com/
  Uses Wix API with dynamic token authentication.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @category_id "76568aeb-0d3b-4a83-8b2a-f71ed1e8c1f0"
  @comp_id "comp-m1qup2z8"

  @impl true
  def source_url do
    "https://www.theredwoodtheatre.com/_api/wix-one-events-server/html/v2/widget-data?" <>
      "compId=#{@comp_id}&locale=en&regional=en-ca&viewMode=site&members=false" <>
      "&paidPlans=true&responsive=false&widgetType=2&listLayout=3&calendarEvents=false" <>
      "&showcase=false&tz=America%2FToronto&filterType=2&noCategoryIdFallback=false" <>
      "&limit=100&newClassicEvents=true&editor3=false&fetchBadges=true" <>
      "&categoryId=#{@category_id}&fetchAllCategories=false"
  end

  @impl true
  def retrieve_events_fun do
    fn url ->
      headers = [
        {"accept", "application/json, text/plain, */*"},
        {"authorization",
         "PdPzbEOTs9xe6nF3LPEyL5MlAJclwDqcGjfy7R8V0Jw.eyJpbnN0YW5jZUlkIjoiMGJiZDUxNDktMTkwNS00NDkyLWJjYWEtNDMxNjgzYzE4MDFkIiwiYXBwRGVmSWQiOiIxNDA2MDNhZC1hZjhkLTg0YTUtMmM4MC1hMGY2MGNiNDczNTEiLCJtZXRhU2l0ZUlkIjoiOTAyMDIwNTItZTQxZC00YzEwLThlMTEtZTljNjdhZTEzNjdjIiwic2lnbkRhdGUiOiIyMDI2LTAxLTEyVDIxOjE5OjU3LjYxN1oiLCJkZW1vTW9kZSI6ZmFsc2UsImFpZCI6IjFmODJiMzI1LTFiYjQtNDYwNi04YzQ5LWRmNDI2Y2FmYTUzNiIsImJpVG9rZW4iOiI5YjlkNzExYi1mZDE4LTA4ODItMzJiYi1hYWQwZjkyMGI2NjEiLCJzaXRlT3duZXJJZCI6ImNjNTIzYWJjLTUxNTQtNGM4YS04ZDk2LTIxZjI0ODFiYjU0NiIsImJzIjoiMXhrRm5CRFVTUXhEcGNXYzFhRGctbTJZOTZkQWY0ZXdRNms4TlBSS3ZLayIsInNjZCI6IjIwMjQtMDYtMjdUMjA6MDk6MDAuMDYyWiJ9"}
      ]

      HttpClient.get(url, headers)
    end
  end

  @impl true
  def example_data_file_location, do: "test/data/redwood_theatre/index.json"

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> get_in(["component", "events"])
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
