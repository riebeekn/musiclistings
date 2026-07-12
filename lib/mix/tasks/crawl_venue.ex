defmodule Mix.Tasks.CrawlVenue do
  @shortdoc "Crawls the given venues (by parser module name)"

  @moduledoc """
  Crawls one or more venues from this machine and saves the results to whichever
  database the app is configured against.

  This exists because a couple of venues (currently Wiggle Room and Junction
  Underground, both on the same Hostinger box) silently drop Render's egress IP
  at the TCP layer, so the nightly crawl can never reach them - see
  `bin/crawl-venue.sh`, which runs this against the production database.

  Venues are identified by their `parser_module_name` rather than their id, since
  ids are assigned per environment and so differ between dev and prod - a command
  copied out of the crawl summary email has to mean the same venue everywhere.

  Usage:
    mix crawl_venue WiggleRoomParser
    mix crawl_venue WiggleRoomParser JunctionUndergroundParser
  """
  use Mix.Task

  alias MusicListings.Crawler
  alias MusicListings.Venues

  @requirements ["app.start"]

  @impl true
  def run([]) do
    Mix.raise("""
    No venues given.

    Usage:
      mix crawl_venue WiggleRoomParser
      mix crawl_venue WiggleRoomParser JunctionUndergroundParser
    """)
  end

  def run(args) do
    venues = Enum.map(args, &fetch_venue!/1)

    Mix.shell().info("Crawling: #{Enum.map_join(venues, ", ", & &1.name)}")

    case Crawler.crawl(venues) do
      {:ok, crawl_summary} ->
        Mix.shell().info("""

        Done.
          new:       #{crawl_summary.new}
          updated:   #{crawl_summary.updated}
          duplicate: #{crawl_summary.duplicate}
          ignored:   #{crawl_summary.ignored}
          errors:    #{crawl_summary.errors}
        """)

      {:error, changeset} ->
        Mix.raise("Crawl failed: #{inspect(changeset)}")
    end
  end

  defp fetch_venue!(parser_module_name) do
    case Venues.fetch_venue_by_parser_module_name(parser_module_name) do
      {:ok, venue} ->
        venue

      {:error, :venue_not_found} ->
        Mix.raise("No venue found with parser module name #{inspect(parser_module_name)}")
    end
  end
end
