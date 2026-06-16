defmodule MusicListings.Repo.Migrations.SeedShowRecentlyAddedFlag do
  use Ecto.Migration

  # Seeds the `:show_recently_added` FunWithFlags feature flag in a disabled (off)

  def up do
    execute("""
    INSERT INTO feature_flags (flag_name, gate_type, target, enabled)
    VALUES ('show_recently_added', 'boolean', '_fwf_none', false)
    ON CONFLICT (flag_name, gate_type, target) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM feature_flags
    WHERE flag_name = 'show_recently_added' AND gate_type = 'boolean'
    """)
  end
end
