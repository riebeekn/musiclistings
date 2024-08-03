defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.IgnoredEvent

  require Logger

  @spec ignore_crawl_error(pos_integer()) :: IgnoredEvent
  def ignore_crawl_error(crawl_error_id) do
    crawl_error =
      CrawlError
      |> Repo.get!(crawl_error_id)
      |> Repo.preload(:venue)

    parser =
      String.to_existing_atom(
        "Elixir.MusicListings.Parsing.VenueParsers.#{crawl_error.venue.parser_module_name}"
      )

    ignored_event_id =
      crawl_error.raw_event
      |> parser.events()
      |> Enum.at(0)
      |> parser.ignored_event_id()

    %IgnoredEvent{
      ignored_event_id: ignored_event_id,
      venue_id: crawl_error.venue_id
    }
    |> Repo.insert!()
  rescue
    error ->
      Logger.error("Failed to insert ignored event record.")
      Logger.error(error)
  end
end
