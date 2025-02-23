defmodule MusicListings.Repo.Migrations.AddArraymusicToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('Arraymusic', 'ArraymusicParser', true, '155 Walnut Ave', 'Toronto', 'Ontario', 'Cananda', 'M6J 3W3', 'http://www.arraymusic.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d1443.5906787497227!2d-79.41070100873718!3d43.64439498926088!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3506b25ef56b%3A0x92db647bfae90d55!2sArraymusic!5e0!3m2!1sen!2sca!4v1740090154705!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Arraymusic'
    """
  end
end
