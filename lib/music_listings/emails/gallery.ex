defmodule MusicListings.Emails.Gallery do
  @moduledoc """
  Swoosh preview gallery items
  """
  use Swoosh.Gallery

  group "/admin", title: "Admin" do
    preview("/contact", MusicListings.Emails.ContactUs)
    preview("/latest_crawl_results", MusicListings.Emails.LatestCrawlResults)
    preview("/new_submitted_event", MusicListings.Emails.NewSubmittedEvent)
    preview("/new_this_week_analytics", MusicListings.Emails.NewThisWeekAnalytics)
  end
end
