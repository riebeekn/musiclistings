defmodule MusicListings.CrawlSummariesFixtures do
  @moduledoc false
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlSummary

  def crawl_summary_fixture do
    Repo.insert!(%CrawlSummary{})
  end
end
