defmodule MusicListings.Workers.ParserHealthWorker do
  @moduledoc """
  Worker which scans recent crawl history for venues whose parser yield has
  pulled back and emails the findings to the site admin. Scheduled via Oban cron.
  """
  use Oban.Worker

  alias MusicListings.Emails.ParserPullback
  alias MusicListings.Mailer
  alias MusicListings.ParserHealth

  @impl Oban.Worker
  def perform(_job) do
    ParserHealth.pullback_report()
    |> ParserPullback.new_email()
    |> Mailer.deliver()

    :ok
  end
end
