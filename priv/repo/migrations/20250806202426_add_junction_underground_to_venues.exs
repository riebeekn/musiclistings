defmodule MusicListings.Repo.Migrations.AddJunctionUndergroundToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('Junction Underground', 'JunctionUndergroundParser', true, '2907 Dundas St W', 'Toronto', 'Ontario', 'Canada', 'M6P 1Z2', 'https://junctionunderground.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.2761965843897!2d-79.4693909!3d43.6639109!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b340f0e4b1d8f%3A0xf5e5c7e1e5f5e5e5!2sJunction%20Underground!5e0!3m2!1sen!2sca!4v1725741558858!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Junction Underground'
    """
  end
end
