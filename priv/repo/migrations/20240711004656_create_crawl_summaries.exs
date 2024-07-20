defmodule MusicListings.Repo.Migrations.CreateCrawlSummaries do
  use Ecto.Migration

  def change do
    create table(:crawl_summaries) do
      add :new, :integer
      add :updated, :integer
      add :duplicate, :integer
      add :parse_errors, :integer
      add :errors, :integer
      add :errors_dump, {:array, :map}

      timestamps()
    end
  end
end
