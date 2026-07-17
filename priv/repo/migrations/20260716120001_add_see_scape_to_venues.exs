defmodule MusicListings.Repo.Migrations.AddSeeScapeToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('See-Scape', 'SeeScapeParser', true, '347 Keele Street', 'Toronto', 'Ontario', 'Canada', 'M6P 2K6', 'https://www.seescapeto.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.205714617606!2d-79.4640622!3d43.6646913!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b342210f4ccf1%3A0x41f44b9e50b376b3!2sSee-Scape!5e0!3m2!1sen!2sca!4v1784247584329!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'See-Scape'
    """)
  end
end
