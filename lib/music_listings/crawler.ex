defmodule MusicListings.Crawler do
  @moduledoc """
  Crawler for retrieving events
  """
  alias MusicListings.Crawler.CrawlSummary
  alias MusicListings.Crawler.DataSource
  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.EventStorage
  alias MusicListings.Parsing.DanforthMusicHallParser
  alias MusicListings.Parsing.VelvetUndergroundParser
  alias MusicListings.Repo
  alias MusicListingsSchema.Venue

  require Logger

  @type crawler_opts :: {:pull_data_from_www, boolean()}
  @type parser_types :: DanforthMusicHallParser | VelvetUndergroundParser

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
  @spec crawl(parsers :: list(parser_types), opts :: list(crawler_opts)) :: list(Payload)
  def crawl(parsers, opts \\ []) do
    pull_data_from_www? = Keyword.get(opts, :pull_data_from_www, false)

    Enum.flat_map(parsers, fn parser ->
      venue = Repo.get_by!(Venue, name: parser.venue_name())

      parser
      |> DataSource.retrieve_events(parser.source_url(), pull_data_from_www?)
      |> EventParser.parse_events(parser, venue)
      |> EventStorage.save_events()
    end)
  end

  @doc """
  Takes a list of completed payloads and produces a summary of the result
  of the crawl process
  """
  @spec crawl_summary(payloads :: list(Payload)) :: CrawlSummary
  defdelegate crawl_summary(payloads), to: CrawlSummary, as: :new

  def save_crawl_summary(crawl_summary) do
    %MusicListingsSchema.CrawlSummary{
      new: crawl_summary.new,
      updated: crawl_summary.updated,
      duplicate: crawl_summary.duplicate,
      parse_errors: crawl_summary.parse_errors,
      errors: crawl_summary.errors,
      parse_errors_dump: crawl_summary.parse_errors_dump,
      errors_dump: crawl_summary.errors_dump
    }
    |> Repo.insert()
  end
end
