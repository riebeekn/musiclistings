defmodule MusicListings.Repo.Migrations.RemoveErrorTrackerTables do
  use Ecto.Migration

  def change do
    drop table(:error_tracker_occurrences)
    drop table(:error_tracker_errors)
    drop table(:error_tracker_meta)
  end
end
