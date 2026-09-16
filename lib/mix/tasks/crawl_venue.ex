defmodule Mix.Tasks.CrawlVenue do
  @shortdoc "Crawls the given venues (by parser module name)"

  @moduledoc """
  Crawls one or more venues from this machine, saves the results to whichever
  database the app is configured against, and emails the admin a crawl report
  just like the nightly crawl does.

  This exists because a number of venues silently drop Render's egress IP at
  the TCP layer, so the nightly crawl can never reach them - see
  `bin/crawl-venue.sh`, which runs this against the production database.

  Venues are identified by their `parser_module_name` rather than their id, since
  ids are assigned per environment and so differ between dev and prod - a command
  copied out of the crawl summary email has to mean the same venue everywhere.

  The report is titled "Local Crawl Report" so it is distinguishable from the
  nightly one.  It goes wherever the mailer is configured to send it: the local
  Swoosh mailbox (http://localhost:4000/dev/mailbox) by default, or the real
  admin inbox via Brevo when `USE_PROD_DB=true` (see `config/dev.exs`).

  Usage:
    mix crawl_venue WiggleRoomParser
    mix crawl_venue WiggleRoomParser JunctionUndergroundParser
  """
  use Mix.Task

  alias MusicListings.Crawler
  alias MusicListings.Curation
  alias MusicListings.Emails.LatestCrawlResults
  alias MusicListings.Mailer
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

        send_report(crawl_summary)

      {:error, changeset} ->
        Mix.raise("Crawl failed: #{inspect(changeset)}")
    end
  end

  # Mirrors the tail of DataRetrievalWorker, minus the TicketNetwork pass: that
  # one refetches the whole affiliate catalog and rewrites links across every
  # event, which is the nightly crawl's job - anything added here is picked up
  # the following night.  Curation is cheap (database only) and reviews what
  # this crawl just wrote, so it runs.
  defp send_report(crawl_summary) do
    Curation.run_quietly()

    email =
      LatestCrawlResults.new_email(crawl_summary,
        title: "Local Crawl Report",
        ticket_network_result: :skipped
      )

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        Mix.shell().info("Crawl report emailed to #{recipient(email)}")

      {:error, reason} ->
        Mix.shell().error("Failed to email crawl report: #{inspect(reason)}")
    end
  end

  defp recipient(%Swoosh.Email{to: [{_name, address} | _rest]}), do: address

  defp fetch_venue!(parser_module_name) do
    case Venues.fetch_venue_by_parser_module_name(parser_module_name) do
      {:ok, venue} ->
        venue

      {:error, :venue_not_found} ->
        Mix.raise("No venue found with parser module name #{inspect(parser_module_name)}")
    end
  end
end
