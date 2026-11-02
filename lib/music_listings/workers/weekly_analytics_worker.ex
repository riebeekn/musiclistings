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
    report = Analytics.weekly_engagement()

    report
    |> WeeklyAnalytics.new_email()
    |> Mailer.deliver()

    # Coverage is current state, so save it for next week's report to compare against.
    Analytics.record_ticket_coverage(report.ticket_coverage)

    :ok
  end
end
