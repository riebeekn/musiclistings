defmodule MusicListings.Repo.Migrations.AddBerczyTavernToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Berczy Tavern', 'BerczyTavernParser', true, '69 Front St E', 'Toronto', 'Ontario', 'Canada', 'M5E 1B5', 'https://www.theberczy.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.984895338535!2d-79.37333459999999!3d43.6484826!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cbec1c6ba589%3A0xaca965450d111888!2sThe%20Berczy%20Tavern!5e0!3m2!1sen!2sca!4v1794021836479!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Berczy Tavern'
    """)
  end
end
