defmodule MusicListings.Repo.Migrations.AddTimothysPubToVenues do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Timothy''s Pub', 'TimothysPubParser', 'true', '344 Browns Line', 'Toronto', 'Ontario', 'Canada', 'M8W 3T7', 'https://www.timothyspub.ca', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2889.308267536826!2d-79.544865!3d43.6001227!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b48139fdbd05d%3A0x5f91c4ed33285a80!2sTimothy&#39;s%20Pub!5e0!3m2!1sen!2sca!4v1763310550477!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Timothy''s Pub'
    """
  end
end
