defmodule MusicListings.Repo.Migrations.SeedMoreVenues9 do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Meridian Hall', 'MeridianHallParser', true, '1 Front St E', 'Toronto', 'Ontario', 'Cananda', 'M5E 1B2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.287621206979!2d-79.3760205!3d43.6466723!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb2db063a1b1%3A0x40afbfba1f58eda2!2sMeridian%20Hall!5e0!3m2!1sen!2sca!4v1726519195569!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Meridian Hall'
    """
  end
end
