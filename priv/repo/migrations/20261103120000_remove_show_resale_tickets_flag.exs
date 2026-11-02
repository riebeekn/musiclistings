defmodule MusicListings.Repo.Migrations.RemoveShowResaleTicketsFlag do
  use Ecto.Migration

  # The TicketNetwork resale links have been removed, so the `:show_resale_tickets`
  # FunWithFlags flag is no longer read anywhere. Deleting the row also drops it
  # from the /feature_flags admin UI.

  def up do
    execute("""
    DELETE FROM feature_flags
    WHERE flag_name = 'show_resale_tickets'
    """)
  end

  def down do
    execute("""
    INSERT INTO feature_flags (flag_name, gate_type, target, enabled)
    VALUES ('show_resale_tickets', 'boolean', '_fwf_none', false)
    ON CONFLICT (flag_name, gate_type, target) DO NOTHING
    """)
  end
end
