defmodule MusicListings.Repo.Migrations.AddDeletedAtToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :deleted_at, :timestamp, default: nil
    end
  end
end
