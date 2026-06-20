defmodule MusicListings.Repo.Migrations.CreateAnalyticsEvents do
  use Ecto.Migration

  def change do
    create table(:analytics_events) do
      add :name, :string, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(updated_at: false)
    end

    create index(:analytics_events, [:name])
    create index(:analytics_events, [:inserted_at])
  end
end
