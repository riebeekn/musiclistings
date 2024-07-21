defmodule MusicListings.Repo.Migrations.CreateCrawlSummaries do
  use Ecto.Migration

  def change do
    create table(:crawl_summaries) do
      add :new, :integer
      add :updated, :integer
      add :duplicate, :integer
      add :parse_errors, :integer

      timestamps()
    end
  end
end
