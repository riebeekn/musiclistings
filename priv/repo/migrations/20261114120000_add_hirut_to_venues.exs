defmodule MusicListings.Repo.Migrations.AddHirutToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Hirut Cafe', 'HirutParser', true, '2050 Danforth Ave', 'Toronto', 'Ontario', 'Canada', 'M4C 1J6', 'https://www.hirutjazz.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.1997071703554!2d-79.3138687!3d43.6856114!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc6b58b737a5%3A0xaf71162a5ca134b9!2sHirut%20Cafe%20And%20Restaurant!5e0!3m2!1sen!2sus!4v1794680592051!5m2!1sen!2sus')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Hirut Cafe'
    """)
  end
end
