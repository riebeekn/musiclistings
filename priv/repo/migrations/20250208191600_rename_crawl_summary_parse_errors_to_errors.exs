defmodule MusicListings.Repo.Migrations.RenameCrawlSummaryParseErrorsToErrors do
  use Ecto.Migration

  def change do
    rename table("crawl_summaries"), :parse_errors, to: :errors
  end
end
