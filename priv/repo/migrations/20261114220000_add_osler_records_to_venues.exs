defmodule MusicListings.Repo.Migrations.AddOslerRecordsToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Osler Records', 'OslerRecordsParser', true, '2a Osler Street', 'Toronto', 'Ontario', 'Canada', 'M6P 4A2', 'https://www.instagram.com/osler.records', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.202147161923!2d-79.4569039!3d43.664765499999994!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b355117e03969%3A0x2e5ccc7806cbfb6e!2sOsler%20Records!5e0!3m2!1sen!2sus!4v1794682724234!5m2!1sen!2sus')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Osler Records'
    """)
  end
end
