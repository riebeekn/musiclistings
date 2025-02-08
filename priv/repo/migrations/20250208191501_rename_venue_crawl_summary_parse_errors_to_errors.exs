defmodule MusicListings.Repo.Migrations.RenameVenueCrawlSummaryParseErrorsToErrors do
  use Ecto.Migration

  def change do
    rename table("venue_crawl_summaries"), :parse_errors, to: :errors
  end
end
