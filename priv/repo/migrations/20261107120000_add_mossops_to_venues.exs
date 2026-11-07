defmodule MusicListings.Repo.Migrations.AddMossopsToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Mossop''s Social House', 'MossopsParser', true, '56 Yonge St', 'Toronto', 'Ontario', 'Canada', 'M5E 1G5', 'https://mossops.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.9991464634204!2d-79.3777157!3d43.648186100000004!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb4ec8a007fd%3A0x57427adaf49c6aed!2sMossop''s%20Social%20House!5e0!3m2!1sen!2sca!4v1794086770215!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Mossop''s Social House'
    """)
  end
end
