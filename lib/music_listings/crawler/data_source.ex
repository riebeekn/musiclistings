defmodule MusicListings.Crawler.DataSource do
  @moduledoc """
  Recursively consumes html files from the internet
  and parses these files into a list of Payloads containing the
  html for individual events in the form of a Meeseeks result
  """
  alias MusicListings.Crawler.Payload
  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.VenueParser

  require Logger

  @spec retrieve_events(
          parser :: VenueParser,
          url :: String.t(),
          events :: list(Payload)
        ) :: list(Payload)
  def retrieve_events(parser, url, payloads \\ []) do
    fun = parser.retrieve_events_fun()

    try do
      fun.(url)
      |> case do
        {:ok, %Response{status: 200, body: body}} ->
          events_from_current_body =
            body
            |> parser.events()
            |> case do
              nil ->
                Logger.warning("Found no events to parse")
                []

              events ->
                Enum.map(events, &Payload.new/1)
            end

          next_page_url = parser.next_page_url(body, url)

          if next_page_url do
            retrieve_events(parser, next_page_url, payloads ++ events_from_current_body)
          else
            payloads ++ events_from_current_body
          end

        {:ok, %Response{status: status}} ->
          Logger.warning("Failed to get data from #{url}, status code: #{status}")
          []

        {:error, error} ->
          Logger.error("Error occured getting #{url}, #{inspect(error)}")
          []
      end
    rescue
      error ->
        Logger.error("Request failed with #{inspect(error)}")
        []
    end
  end
end
