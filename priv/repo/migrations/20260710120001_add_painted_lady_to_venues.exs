defmodule MusicListings.Repo.Migrations.AddPaintedLadyToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Painted Lady', 'PaintedLadyParser', true, '218 Ossington Avenue', 'Toronto', 'Ontario', 'Canada', 'M6J 2Z9', 'https://www.thepaintedlady.ca', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.953441654714!2d-79.4208611!3d43.649136999999996!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34f94e78a89b%3A0xe9a20e5da7d79611!2sThe%20Painted%20Lady!5e0!3m2!1sen!2sca!4v1783730467657!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Painted Lady'
    """)
  end
end
