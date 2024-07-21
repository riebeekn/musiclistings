defmodule MusicListings.Crawler do
  @moduledoc """
  Crawler for retrieving events
  """
  alias MusicListings.Crawler.CrawlStats
  alias MusicListings.Crawler.DataSource
  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.EventStorage
  alias MusicListings.Parsing.Parser
  alias MusicListings.Repo
  alias MusicListingsSchema.Venue

  require Logger

  @type crawler_opts :: {:pull_data_from_www, boolean()}

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
  @spec crawl(parsers :: list(Parser), opts :: list(crawler_opts)) ::
          {:ok, CrawlSummary} | {:error, Ecto.Changeset}
  def crawl(parsers, opts \\ []) do
    pull_data_from_www? = Keyword.get(opts, :pull_data_from_www, false)

    crawl_summary = init_crawl_summary()

    parsers
    |> Enum.flat_map(fn parser ->
      venue = Repo.get_by!(Venue, name: parser.venue_name())

      parser
      |> DataSource.retrieve_events(parser.source_url(), pull_data_from_www?)
      |> EventParser.parse_events(parser, venue, crawl_summary)
      |> EventStorage.save_events()
    end)
    |> CrawlStats.new()
    |> update_crawl_summary_with_stats(crawl_summary)
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
