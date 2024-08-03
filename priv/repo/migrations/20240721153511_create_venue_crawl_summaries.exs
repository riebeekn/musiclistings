defmodule MusicListings.Repo.Migrations.CreateVenueCrawlSummaries do
  use Ecto.Migration

  def change do
    create table(:venue_crawl_summaries) do
      add :venue_id, references(:venues), null: false
      add :crawl_summary_id, references(:crawl_summaries), null: false
      add :new, :integer
      add :updated, :integer
      add :duplicate, :integer
      add :ignored, :integer
      add :parse_errors, :integer

      timestamps(updated_at: false)
    end
  end
end
