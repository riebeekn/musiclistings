defmodule MusicListings.Repo.Migrations.AddSneakyDeesToVenues do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Sneaky Dee''s', 'SneakyDeesParser', 'true', '431 College St', 'Toronto', 'Ontario', 'Canada', 'M5T 1T2', 'https://www.sneakydees.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d5773.225235997845!2d-79.4074217!3d43.6562274!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34ebe22e5853%3A0x1ed72ff031eed0bf!2sSneaky%20Dee&#39;s!5e0!3m2!1sen!2sca!4v1763157837543!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Sneaky Dee''s'
    """
  end
end
