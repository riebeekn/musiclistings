defmodule MusicListings.Repo.Migrations.AddInsertedAtIndexToEvents do
  use Ecto.Migration

  def change do
    # Supports the "recently added" feed query, which filters/sorts on inserted_at
    # over non-deleted events.
    create index(:events, [:inserted_at], where: "deleted_at IS NULL")
  end
end
