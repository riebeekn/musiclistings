defmodule MusicListings.Repo.Migrations.CreateSubmittedEvents do
  use Ecto.Migration

  def change do
    create table(:submitted_events) do
      add :title, :string, null: false
      add :venue, :string, null: false
      add :date, :date, null: false
      add :time, :string
      add :price, :string
      add :url, :string, size: 2048

      timestamps(updated_at: false)
    end
  end
end
