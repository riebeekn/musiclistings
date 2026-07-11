defmodule MusicListings.Repo.Migrations.AddRhythmToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Rhythm', 'RhythmParser', true, '141 Bathurst St Suite 101', 'Toronto', 'Ontario', 'Canada', 'M5V 2R2', 'https://rhythm.space/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2887.101387005316!2d-79.402784!3d43.64605890000001!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b352c43020f89%3A0x269725da130a13db!2sRhythm%20Toronto!5e0!3m2!1sen!2sca!4v1783777490826!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Rhythm'
    """)
  end
end
