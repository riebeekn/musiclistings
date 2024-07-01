defmodule MusicListings.Repo.Migrations.PopulateInitialVenues do
  use Ecto.Migration

  def up do
    execute "INSERT INTO venues(name) VALUES('Velvet Underground')"
    execute "INSERT INTO venues(name) VALUES('Danforth Music Hall')"
    execute "INSERT INTO venues(name) VALUES('Horseshoe Tavern')"
  end

  def down do
    execute "DELETE FROM venues"
  end
end
