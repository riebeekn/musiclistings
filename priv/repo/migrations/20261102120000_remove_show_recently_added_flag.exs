defmodule MusicListings.Repo.Migrations.RemoveShowRecentlyAddedFlag do
  use Ecto.Migration

  # The "New This Week" rail has been removed, so its `:show_recently_added`
  # FunWithFlags flag is no longer read anywhere. Deleting the row also drops it
  # from the /feature_flags admin UI.

  def up do
    execute("""
    DELETE FROM feature_flags
    WHERE flag_name = 'show_recently_added'
    """)
  end

  def down do
    execute("""
    INSERT INTO feature_flags (flag_name, gate_type, target, enabled)
    VALUES ('show_recently_added', 'boolean', '_fwf_none', false)
    ON CONFLICT (flag_name, gate_type, target) DO NOTHING
    """)
  end
end
