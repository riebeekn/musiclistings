defmodule MusicListings.Workers.NewThisWeekAnalyticsWorker do
  @moduledoc """
  Worker which assembles the weekly "New This Week" rail traction report and
  emails it to the site admin. Scheduled via Oban cron.
  """
  use Oban.Worker

  alias MusicListings.Analytics
  alias MusicListings.Emails.NewThisWeekAnalytics
  alias MusicListings.Mailer

  @impl Oban.Worker
  def perform(_job) do
    Analytics.weekly_rail_traction()
    |> NewThisWeekAnalytics.new_email()
    |> Mailer.deliver()

    :ok
  end
end
