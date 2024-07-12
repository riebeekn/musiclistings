defmodule MusicListings.Emails.Gallery do
  @moduledoc """
  Swoosh preview gallery items
  """
  use Swoosh.Gallery

  group "/admin", title: "Admin" do
    preview("/latest_crawl_results", MusicListings.Emails.LatestCrawlResults)
  end
end
