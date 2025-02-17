defmodule Mix.Tasks.ListLiveNationVenues do
  @moduledoc """
  Simple mix task to iterate over the venue list maintained by live nation and output those with
  events tracked by live nation to a CSV file.  LN lists ~800 venues in Toronto, but of those
  only ~50 have events tracked by LN.

  Usage: mix list_live_nation_venues
  """
  use Mix.Task

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.VenueParsers.BaseParsers.LiveNationParser
  alias NimbleCSV.RFC4180, as: CSV

  require Logger

  @requirements ["app.start"]

  @impl true
  def run(_opts) do
    venues = retrieve_venues()

    data =
      venues
      |> Enum.map(fn venue ->
        %{venue_name: venue["name"], code: venue["objectID"]}
      end)
      |> Enum.reject(&no_events?/1)
      |> Enum.sort_by(& &1.venue_name)
      |> Enum.map(&[&1.venue_name, &1.code])

    header = ["VENUE", "CODE"]

    data_with_header =
      [header | data]
      |> CSV.dump_to_iodata()

    File.write!("venues.csv", data_with_header)
    Logger.info("Wrote venue information to venues.csv")
  end

  defp retrieve_venues do
    url = "https://cke1fgpup4-dsn.algolia.net/1/indexes/*/queries"

    headers = [
      {"x-algolia-api-key", "0661dcea58e0be5ae40b98c29a6ad229"},
      {"x-algolia-application-id", "CKE1FGPUP4"}
    ]

    request_body =
      %{
        "requests" => [
          %{
            "indexName" => "prod-venue-index",
            "params" =>
              "analyticsTags=%5B%22desktop%22%5D&aroundLatLng=43.66%2C-79.38&getRankingInfo=true" <>
                "&highlightPostTag=__%2Fais-highlight__&highlightPreTag=__ais-highlight__" <>
                "&page=0&hitsPerPage=1000&attributesToRetrieve=name,objectID&getRankingInfo=false&query=toronto"
          }
        ]
      }

    {:ok, %{status: 200, body: body}} = HttpClient.post(url, request_body, headers)

    decoded_body = Jason.decode!(body)
    results = decoded_body["results"] |> List.first()
    results["hits"]
  end

  defp no_events?(%{code: code, venue_name: venue_name}) do
    Logger.info("Checking events for: #{venue_name}")

    fun = LiveNationParser.retrieve_events_fun(code)
    {:ok, %{status: 200, body: body}} = fun.(LiveNationParser.source_url())
    decoded_body = Jason.decode!(body)
    # treat venues with <= 5 events as having no events
    Enum.count(decoded_body["data"]["getEvents"]) <= 5
  end
end
