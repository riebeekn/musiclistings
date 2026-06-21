defmodule MusicListings.Repo.Migrations.AddDeletedAtToSubmittedEvents do
  use Ecto.Migration

  def change do
    alter table(:submitted_events) do
      add :deleted_at, :timestamp, default: nil
    end
  end
end
