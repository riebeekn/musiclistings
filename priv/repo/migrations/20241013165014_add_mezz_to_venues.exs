defmodule MusicListings.Repo.Migrations.AddMezzToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('The Mezz', 'n/a', false, '1546 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M6R 1A6', 'https://www.instagram.com/mezzparkdale', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11549.55423666736!2d-79.4397216!3d43.6400836!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35b17ecc4353%3A0x13f1ee02099b5d5b!2sThe%20Mezz!5e0!3m2!1sen!2sca!4v1728838389676!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'The Mezz'
    """
  end
end
