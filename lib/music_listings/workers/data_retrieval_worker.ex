defmodule MusicListings.Workers.DataRetrievalWorker do
  @moduledoc """
  Worker which pulls venues from the DB and passes these off
  to the crawler to retrieve data
  """
  use Oban.Worker

  import Ecto.Query

  alias MusicListings.Affiliates.TicketNetwork
  alias MusicListings.Crawler
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
        # Runs after the crawl so it matches against fresh event data.  Failures
        # are logged and folded in as a nil stat rather than raised - a
        # TicketNetwork outage must not cost us the crawl summary email.
        ticket_network_stats = TicketNetwork.run_quietly()

        crawl_summary
        |> LatestCrawlResults.new_email(nil, ticket_network_stats)
        |> Mailer.deliver()

      _error ->
        :noop
    end

    :ok
  end
end
