defmodule MusicListings.Repo.Migrations.CreateCrawlSummaries do
  use Ecto.Migration

  def change do
    create table(:crawl_summaries) do
      add :new, :integer, null: false
      add :updated, :integer, null: false
      add :duplicate, :integer, null: false
      add :parse_errors, :integer, null: false
      add :errors, :integer, null: false
      add :parse_errors_dump, {:array, :map}
      add :errors_dump, {:array, :map}

      timestamps(updated_at: false)
    end
  end
end
