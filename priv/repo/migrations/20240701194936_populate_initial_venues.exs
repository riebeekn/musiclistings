defmodule MusicListings.Repo.Migrations.PopulateInitialVenues do
  use Ecto.Migration

  def up do
    execute "INSERT INTO venues(name, parser_module_name) VALUES('Velvet Underground', 'MusicListings.Parsing.VelvetUndergroundParser')"

    execute "INSERT INTO venues(name, parser_module_name) VALUES('Danforth Music Hall', 'MusicListings.Parsing.DanforthMusicHallParser')"

    execute "INSERT INTO venues(name, parser_module_name) VALUES('Horseshoe Tavern', 'MusicListings.Parsing.HorseshoeTavenrParser')"
  end

  def down do
    execute "DELETE FROM venues"
  end
end
