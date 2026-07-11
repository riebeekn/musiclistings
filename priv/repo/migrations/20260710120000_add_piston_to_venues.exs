defmodule MusicListings.Repo.Migrations.AddPistonToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Piston', 'PistonParser', true, '937 Bloor Street West', 'Toronto', 'Ontario', 'Canada', 'M6H 1L5', 'https://www.thepiston.ca', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.364745143296!2d-79.42761569999999!3d43.6613835!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b345fb7242c47%3A0x43f588563d688a67!2sThe%20Piston!5e0!3m2!1sen!2sca!4v1783730532004!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Piston'
    """)
  end
end
