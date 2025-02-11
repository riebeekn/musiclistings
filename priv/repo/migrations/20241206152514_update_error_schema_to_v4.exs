defmodule MusicListings.Repo.Migrations.UpdateErrorSchemaToV4 do
  use Ecto.Migration

  def up, do: ErrorTracker.Migration.up(version: 4)

  # We specify `version: 1` in `down`, to ensure we remove all migrations.
  def down, do: ErrorTracker.Migration.down(version: 1)
end
