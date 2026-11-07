defmodule MusicListings.Repo.Migrations.AddDrumsNFlatsToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Drums N Flats', 'DrumsNFlatsParser', true, '1980 Avenue Rd', 'Toronto', 'Ontario', 'Canada', 'M5M 4A4', 'https://www.drumsnflats.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2882.817526796279!2d-79.42026589999999!3d43.7351174!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b32f47a0b398f%3A0x4342c58478111926!2sDrums%20N%20Flats!5e0!3m2!1sen!2sca!4v1794087355075!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Drums N Flats'
    """)
  end
end
