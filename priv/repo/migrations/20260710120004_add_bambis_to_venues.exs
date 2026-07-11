defmodule MusicListings.Repo.Migrations.AddBambisToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Bambi''s', 'BambisParser', true, '1265 Dundas Street West', 'Toronto', 'Ontario', 'Canada', 'M6J 1X6', 'https://ra.co/clubs/69282', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.9498896334417!2d-79.42446460000001!3d43.64921089999999!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b354082b7d3cf%3A0x39d9fe1012c5118d!2sBambi&#39;s!5e0!3m2!1sen!2sca!4v1783731384040!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Bambi''s'
    """)
  end
end
