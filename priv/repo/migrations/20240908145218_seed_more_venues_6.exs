defmodule MusicListings.Repo.Migrations.SeedMoreVenues6 do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
    VALUES('Tranzac', 'TranzacParser', true, '292 Brunswick Ave', 'Toronto', 'Ontario', 'Cananda', 'M5S 2M7', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11544.711680269234!2d-79.4073917!3d43.6652694!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3494192951b1%3A0xdc2bcb4fcd3c3de3!2sTranzac%20Club!5e0!3m2!1sen!2sca!4v1725807210233!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Tranzac'
    """
  end
end
