defmodule MusicListings.Repo.Migrations.RenameAxisClub do
  use Ecto.Migration

  def up do
    execute """
      UPDATE venues SET name = 'The Mod Club' WHERE name = 'The Axis Club'
    """
  end

  def down do
    execute """
      UPDATE venues SET name = 'The Axis Club' WHERE name = 'The Mod Club'
    """
  end
end
