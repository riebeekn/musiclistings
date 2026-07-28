defmodule MusicListings.Repo.Migrations.SeedShowResaleTicketsFlag do
  use Ecto.Migration

  # Seeds the `:show_resale_tickets` FunWithFlags feature flag in a disabled (off)
  # state. FunWithFlags.all_flag_names/0 only returns persisted flags, so without
  # this row the flag would never appear in the /feature_flags admin UI.

  def up do
    execute("""
    INSERT INTO feature_flags (flag_name, gate_type, target, enabled)
    VALUES ('show_resale_tickets', 'boolean', '_fwf_none', false)
    ON CONFLICT (flag_name, gate_type, target) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM feature_flags
    WHERE flag_name = 'show_resale_tickets' AND gate_type = 'boolean'
    """)
  end
end
