defmodule MusicListings.Workers.WeeklyAnalyticsWorker do
  @moduledoc """
  Worker which assembles the weekly engagement report and emails it to the site
  admin. Scheduled via Oban cron.
  """
  use Oban.Worker

  alias MusicListings.Analytics
  alias MusicListings.Emails.WeeklyAnalytics
  alias MusicListings.Mailer

  @impl Oban.Worker
  def perform(_job) do
    Analytics.weekly_engagement()
    |> WeeklyAnalytics.new_email()
    |> Mailer.deliver()

    :ok
  end
end
