defmodule MusicListings.Repo.Migrations.AddLockedFromUpdatesToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :locked_from_updates, :boolean, null: false, default: false
    end
  end
end
