defmodule MusicListings.Crawler do
  @moduledoc """
  Crawler for retrieving events
  """
  alias MusicListings.Crawler.CrawlStats
  alias MusicListings.Crawler.DataSource
  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.EventStorage
  alias MusicListings.Repo
  alias MusicListingsSchema.Venue
  alias MusicListingsSchema.VenueCrawlSummary

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
      parse_errors: stats.parse_errors
    })
    |> Repo.update()
  end
end
