defmodule MusicListings.Repo.Migrations.ChangeExternalIdsType do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE events ALTER COLUMN external_id TYPE text")
  end

  def down do
    execute("ALTER TABLE events ALTER COLUMN external_id TYPE varchar(255)")
  end
end
