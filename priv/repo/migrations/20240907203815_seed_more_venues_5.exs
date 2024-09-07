defmodule MusicListings.Repo.Migrations.SeedMoreVenues5 do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
    VALUES('Grossman''s Tavern', 'GrossmansParser', true, '377 Spadina Ave', 'Toronto', 'Ontario', 'Cananda', 'M5T 2G3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d5772.805657901198!2d-79.38973415680847!3d43.66059133547621!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34c16f5774e3%3A0x2ec56ddcdb37d3a4!2sGrossman&#39;s%20Tavern!5e0!3m2!1sen!2sca!4v1725741558858!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Grossman''s Tavern'
    """
  end
end
