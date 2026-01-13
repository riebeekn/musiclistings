defmodule MusicListings.Repo.Migrations.EnableRedwoodTheatreParser do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Redwood Theatre', 'RedwoodTheatreParser', 'true', '1300 Gerrard St E', 'Toronto', 'Ontario', 'Canada', 'M4L 1Y7', 'https://www.theredwoodtheatre.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.8910339108143!2d-79.3271529!3d43.671236!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb870b5b1185%3A0x375c5bfd96ab371!2sThe%20Redwood%20Theatre!5e0!3m2!1sen!2sca!4v1767986419879!5m2!1sen!2sca')
    ON CONFLICT (name) DO UPDATE SET
      parser_module_name = EXCLUDED.parser_module_name,
      pull_events = EXCLUDED.pull_events
    """
  end

  def down do
    execute """
    UPDATE venues
    SET parser_module_name = 'n/a', pull_events = 'false'
    WHERE name = 'Redwood Theatre'
    """
  end
end
