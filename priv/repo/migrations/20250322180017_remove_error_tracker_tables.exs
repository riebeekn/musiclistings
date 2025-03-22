defmodule MusicListings.Repo.Migrations.RemoveErrorTrackerTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:error_tracker_occurrences)
    drop_if_exists table(:error_tracker_errors)
    drop_if_exists table(:error_tracker_meta)
  end
end
