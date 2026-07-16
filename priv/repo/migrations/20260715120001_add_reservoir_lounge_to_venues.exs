defmodule MusicListings.Repo.Migrations.AddReservoirLoungeToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Reservoir Lounge', 'ReservoirLoungeParser', true, '52 Wellington Street East', 'Toronto', 'Ontario', 'Canada', 'M5E 1C8', 'https://www.reservoirlounge.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2897.00289400429!2d-79.37456657858871!3d43.648583721919735!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb31ffae1bdd%3A0x64c9edbc257101ce!2sThe%20Reservoir%20Lounge!5e0!3m2!1sen!2sca!4v1784163384624!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Reservoir Lounge'
    """)
  end
end
