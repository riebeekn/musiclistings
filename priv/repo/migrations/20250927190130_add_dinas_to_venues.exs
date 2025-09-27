defmodule MusicListings.Repo.Migrations.AddDinasToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('Dina''s Tavern', 'DinasParser', true, '486 Spadina Ave', 'Toronto', 'Ontario', 'Canada', 'M5S 2H1', 'https://www.dinastavern.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.50819032851!2d-79.40068699999999!3d43.6583997!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35dd84087aab%3A0x396367029b8e7a3f!2sDina&#39;s%20Tavern!5e0!3m2!1sen!2sca!4v1759000211448!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Dina''s Tavern'
    """
  end
end
