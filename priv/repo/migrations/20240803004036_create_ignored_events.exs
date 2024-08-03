defmodule MusicListings.Repo.Migrations.CreateIgnoredEvents do
  use Ecto.Migration

  def change do
    create table(:ignored_events) do
      add :ignored_event_id, :string, null: false
      add :venue_id, references(:venues), null: false

      timestamps()
    end

    create unique_index(:ignored_events, [:ignored_event_id, :venue_id])
  end
end
