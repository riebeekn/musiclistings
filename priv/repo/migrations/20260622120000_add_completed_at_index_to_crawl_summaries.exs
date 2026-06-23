defmodule MusicListings.Repo.Migrations.AddCompletedAtIndexToCrawlSummaries do
  use Ecto.Migration

  def change do
    # Supports data_last_updated_on/0, which selects the most recent completed
    # crawl: filters on completed_at IS NOT NULL and sorts completed_at DESC.
    create index(:crawl_summaries, [:completed_at], where: "completed_at IS NOT NULL")
  end
end
