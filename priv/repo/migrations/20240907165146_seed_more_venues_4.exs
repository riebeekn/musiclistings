defmodule MusicListings.Repo.Migrations.SeedMoreVenues4 do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
    VALUES('Burdock Music Hall', 'BurdockParser', true, '1184 Bloor St W', 'Toronto', 'Ontario', 'Cananda', 'M6H 1N2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11545.821678716064!2d-79.4377609!3d43.6594974!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34435c34cc25%3A0x14da5a68ca57cf6d!2sBurdock%20Brewery!5e0!3m2!1sen!2sca!4v1725728119427!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Burdock Music Hall'
    """
  end
end
