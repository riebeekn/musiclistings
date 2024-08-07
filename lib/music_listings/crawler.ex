defmodule MusicListings.Crawler do
  @moduledoc """
  Crawler for retrieving events
  """
  import Ecto.Query

  alias MusicListings.Crawler.CrawlStats
  alias MusicListings.Crawler.DataSource
  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.EventStorage
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.IgnoredEvent
  alias MusicListingsSchema.Venue
  alias MusicListingsSchema.VenueCrawlSummary
  alias MusicListingsUtilities.DateHelpers

  require Logger

  @type crawler_opts :: {:pull_data_from_www?, boolean()}

  @doc """
  The crawl function is called to retrieve and store events.  Events will
  be inserted or updated depending on whether the event already exists
  in the database.

  ## Parameters

  The function takes in a single required parameter which is a list of
  modules which implement the MusicListings.Parsing.Parser behaviour.
  In this way specific parsers or combination of parsers can be run.

  ## Options

  An optional `:pull_data_from_www` option is available which defaults to false.
  The purpose of this option is to allow for local testing / development to run
  against existing downloaded data files located at `test/data/`

  ## Example

  iex> Crawler.crawl([DanforthMusicHallParser, VelvetUndergroundParser])
  """
  @spec crawl(venues :: list(Venue), opts :: list(crawler_opts)) :: any()
  def crawl(venues, opts \\ []) do
    pull_data_from_www? = Keyword.get(opts, :pull_data_from_www?, false)

    crawl_summary = init_crawl_summary()

    venues
    |> Enum.flat_map(fn venue ->
      parser =
        String.to_existing_atom(
          "Elixir.MusicListings.Parsing.VenueParsers.#{venue.parser_module_name}"
        )

      parser
      |> DataSource.retrieve_events(parser.source_url(), pull_data_from_www?)
      |> EventParser.parse_events(parser, venue, crawl_summary)
      |> EventStorage.save_events()
      |> insert_venue_summary(venue, crawl_summary)
    end)
    |> CrawlStats.new()
    |> update_crawl_summary_with_stats(crawl_summary)
  end

  defp insert_venue_summary(payloads, venue, crawl_summary) do
    venue_stats = CrawlStats.new(payloads)

    %VenueCrawlSummary{
      venue_id: venue.id,
      crawl_summary_id: crawl_summary.id,
      new: venue_stats.new,
      updated: venue_stats.updated,
      duplicate: venue_stats.duplicate,
      ignored: venue_stats.ignored,
      parse_errors: venue_stats.parse_errors
    }
    |> Repo.insert!()

    payloads
  end

  defp init_crawl_summary do
    %MusicListingsSchema.CrawlSummary{}
    |> Repo.insert!()
  end

  defp update_crawl_summary_with_stats(stats, crawl_summary) do
    crawl_summary
    |> Ecto.Changeset.change(%{
      new: stats.new,
      updated: stats.updated,
      duplicate: stats.duplicate,
      ignored: stats.ignored,
      parse_errors: stats.parse_errors
    })
    |> Repo.update()
  end

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

  @spec data_last_updated_on :: String.t()
  def data_last_updated_on do
    CrawlSummary
    |> order_by([crawl_summary], desc: crawl_summary.updated_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil ->
        "No data"

      last_summary ->
        last_summary.updated_at
        |> DateHelpers.to_eastern_datetime()
        |> DateHelpers.format_datetime()
    end
  end
end
