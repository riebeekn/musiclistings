defmodule MusicListings.Crawler.DataSource do
  @moduledoc """
  Recursively consumes html files from either the internet or locally stored
  files and parses these files into a list of Payloads containing the
  html for individual events in the form of a Meeseeks result
  """
  alias MusicListings.Crawler.Payload
  alias MusicListings.Parsing.Parser
  alias Req.Response

  require Logger

  @spec retrieve_events(
          parser :: Parser,
          url :: String.t(),
          pull_data_from_www? :: boolean(),
          events :: list(Payload)
        ) :: list(Payload)
  def retrieve_events(parser, url, pull_data_from_www?, payloads \\ [])

  # Pulls events from www
  def retrieve_events(parser, url, true = _pull_data_from_www?, payloads) do
    url
    |> Req.get()
    |> case do
      {:ok, %Response{status: 200, body: body}} ->
        events_from_current_body =
          body
          |> parser.event_selector()
          |> Enum.map(&Payload.new/1)

        next_page_url = parser.next_page_url(body)

        if next_page_url do
          retrieve_events(parser, next_page_url, true, payloads ++ events_from_current_body)
        else
          payloads ++ events_from_current_body
        end

      {:ok, %Response{status: status}} ->
        Logger.info("Failed to get data from #{url}, status code: #{status}")

      {:error, error} ->
        Logger.error("Error occured getting #{url}, #{inspect(error)}")
    end
  end

  # Pulls events from local file storage
  def retrieve_events(parser, _url, false = _pull_data_from_www?, _payloads) do
    local_data_file = "#{File.cwd!()}/#{parser.example_data_file_location()}"

    local_data_file
    |> Path.expand()
    |> File.read!()
    |> parser.event_selector()
    |> Enum.map(&Payload.new/1)
  end
end
