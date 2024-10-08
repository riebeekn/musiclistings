defmodule MusicListings.Repo.Migrations.SeedRogersStadiumInfo do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Rogers Stadium', 'RogersStadiumParser', true, '105 Carl Hall Road', 'Toronto', 'Ontario', 'Cananda', 'M3K 0A1', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2882.0127841932335!2d-79.4771273!3d43.7518313!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b313aa6b95999%3A0x68eaa03126805c48!2s105%20Carl%20Hall%20Rd%2C%20North%20York%2C%20ON%20M3K%202C1!5e0!3m2!1sen!2sca!4v1728423517005!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Rogers Stadium'
    """
  end
end
