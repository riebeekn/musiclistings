defmodule MusicListings.Repo.Migrations.AddDukeLiveToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Duke Live', 'DukeLiveParser', true, '1225 Queen St E', 'Toronto', 'Ontario', 'Canada', 'M4M 3C3', 'https://dukelive.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.28193296912!2d-79.330365!3d43.663106000000006!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb9cb278bea3%3A0x863c546631deeda2!2sThe%20Duke!5e0!3m2!1sen!2sca!4v1794169407920!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Duke Live'
    """)
  end
end
