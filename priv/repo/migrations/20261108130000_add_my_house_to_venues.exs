defmodule MusicListings.Repo.Migrations.AddMyHouseToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('MY HOUSE', 'MyHouseParser', true, '2882 Dundas St W', 'Toronto', 'Ontario', 'Canada', 'M6P 1Y8', 'https://myhouseinthejunction.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.1627846307665!2d-79.46564459999999!3d43.6655842!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3597fb224dcb%3A0x82e11d6e7ba8eac1!2sMY%20HOUSE!5e0!3m2!1sen!2sca!4v1794169697133!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'MY HOUSE'
    """)
  end
end
