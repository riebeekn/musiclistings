defmodule MusicListings.Repo.Migrations.CreateCrawlErrors do
  use Ecto.Migration

  def change do
    create table(:crawl_errors) do
      add :crawl_summary_id, references(:crawl_summaries), null: false
      add :venue_id, references(:venues), null: false
      add :type, :string
      add :error, :text
      add :raw_event, :text

      timestamps(updated_at: false)
    end
  end
end
