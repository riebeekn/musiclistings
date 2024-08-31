defmodule MusicListings.Repo.Migrations.AddCompletedAtToCrawlSummaries do
  use Ecto.Migration

  def change do
    alter table(:crawl_summaries) do
      add :completed_at, :utc_datetime
    end
  end
end
