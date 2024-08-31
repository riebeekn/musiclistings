defmodule MusicListings.Repo.Migrations.SeedMoreVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Adelaide Hall', 'AdelaideHallParser', true, '250 Adelaide St W', 'Toronto', 'Ontario', 'Cananda', 'M5H 1X6', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.924527500454!2d-79.3889531!3d43.6485609!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34d04c155337%3A0xc92920482f506e63!2sAdelaide%20Hall!5e0!3m2!1sen!2sca!4v1725052386375!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Adelaide Hall'
    """
  end
end
