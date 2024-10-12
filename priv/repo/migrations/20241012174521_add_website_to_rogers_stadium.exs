defmodule MusicListings.Repo.Migrations.AddWebsiteToRogersStadium do
  use Ecto.Migration

  def up do
    execute """
    UPDATE venues SET website = 'https://www.rogers-stadium.com' WHERE name = 'Rogers Stadium'
    """
  end

  def down do
  end
end
