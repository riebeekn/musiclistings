defmodule MusicListings.Repo.Migrations.AddBowlToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Bowl at Sobeys Stadium', 'BowlParser', true, '1 Shoreham Dr', 'Toronto', 'Ontario', 'Canada', 'M3N 3A6', 'https://www.liveatthebowl.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2881.072063930129!2d-79.51199799999999!3d43.77136290000001!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b2f0037b3875f%3A0x5842c72b6baf2d59!2sThe%20Bowl%20at%20Sobeys%20Stadium!5e0!3m2!1sen!2sca!4v1783783546578!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Bowl at Sobeys Stadium'
    """)
  end
end
