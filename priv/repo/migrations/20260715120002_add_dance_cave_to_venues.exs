defmodule MusicListings.Repo.Migrations.AddDanceCaveToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Dance Cave', 'DanceCaveParser', true, '529 Bloor Street West', 'Toronto', 'Ontario', 'Canada', 'M5S 1Y5', 'https://www.leespalace.com/the-dance-cave-calendar', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.1775162003746!2d-79.4094444!3d43.6652778!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3493e58b76d5%3A0x56ebaef8c4ebb58c!2sThe%20Dance%20Cave!5e0!3m2!1sen!2sca!4v1784163423125!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Dance Cave'
    """)
  end
end
