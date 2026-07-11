defmodule MusicListings.Repo.Migrations.AddWiggleRoomToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Wiggle Room', 'WiggleRoomParser', true, '772 Dundas Street West', 'Toronto', 'Ontario', 'Canada', 'M6J 1V1', 'https://wiggleroomtoronto.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.810068840201!2d-79.4074632!3d43.6521198!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b355f1a68d425%3A0x8de0522511226ef0!2sWiggle%20Room%20Toronto!5e0!3m2!1sen!2sca!4v1783730590684!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Wiggle Room'
    """)
  end
end
