defmodule MusicListings.Repo.Migrations.UpdateRogersCentreInfo do
  use Ecto.Migration

  def up do
    execute """
      UPDATE venues SET parser_module_name = 'RogersCentreParser'
      WHERE name = 'Rogers Centre'
    """
  end

  def down do
    execute """
      UPDATE venues SET parser_module_name = 'RogersParser'
      WHERE name = 'Rogers Centre'
    """
  end
end
