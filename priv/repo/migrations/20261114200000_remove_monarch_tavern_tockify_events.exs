defmodule MusicListings.Repo.Migrations.RemoveMonarchTavernTockifyEvents do
  use Ecto.Migration

  # MonarchTavernParser used to read the venue's Tockify calendar, which now only has
  # the upstairs DJ and karaoke nights.  It now reads the venue site's own listings
  # (downstairs shows only), keyed on a different id, so the upcoming Tockify events
  # would otherwise stay listed forever.  The real shows among them (the weekly big
  # bands) are re-added under their new ids by the next crawl.
  def up do
    execute """
    UPDATE events
    SET deleted_at = NOW(), updated_at = NOW()
    WHERE venue_id = (SELECT id FROM venues WHERE parser_module_name = 'MonarchTavernParser')
      AND date >= CURRENT_DATE
      AND deleted_at IS NULL
      AND NOT locked_from_updates
      AND external_id ~ '^monarch_tavern_[0-9]{4}_[0-9]{2}_[0-9]{2}_'
    """
  end

  # The soft-deleted rows can't be told apart from others deleted later, so this is
  # deliberately not reversed
  def down, do: :ok
end
