defmodule MusicListings.Workers.DataRetrievalWorker do
  @moduledoc """
  Worker which pulls venues from the DB and passes these off
  to the crawler to retrieve data
  """
  use Oban.Worker

  import Ecto.Query

  alias MusicListings.Crawler
  alias MusicListings.Curation
  alias MusicListings.Emails.LatestCrawlResults
  alias MusicListings.Mailer
  alias MusicListings.Repo
  alias MusicListingsSchema.Venue

  @impl Oban.Worker
  def perform(_job) do
    query = from(venue in Venue, where: venue.pull_events? == true)

    query
    |> Repo.all()
    |> Crawler.crawl()
    |> case do
      {:ok, crawl_summary} ->
        # Runs after the crawl, since it reviews what the crawl just wrote.  The
        # return value is ignored - the email reads the open flags itself, so a
        # failure here still reports the standing queue.
        Curation.run_quietly()

        crawl_summary
        |> LatestCrawlResults.new_email()
        |> Mailer.deliver()

      _error ->
        :noop
    end

    :ok
  end
end
