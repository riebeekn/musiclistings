defmodule MusicListings.Repo.Migrations.AddComfortZoneToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Comfort Zone', 'ComfortZoneParser', true, '1369 Queen St W', 'Toronto', 'Ontario', 'Canada', 'M6K 1M1', 'https://comfortzonetoronto.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2887.3612432863015!2d-79.4353608!3d43.640651999999996!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35b50bdbb8bb%3A0xa3068463059932e0!2sThe%20Comfort%20Zone!5e0!3m2!1sen!2sca!4v1784163344400!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Comfort Zone'
    """)
  end
end
