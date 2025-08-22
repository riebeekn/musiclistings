defmodule MusicListings.Repo.Migrations.AddHarbourfrontToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('Harbourfront Centre', 'HarbourfrontCentreParser', true, '235 Queens Quay West', 'Toronto', 'Ontario', 'Canada', 'M5J 2G8', 'https://harbourfrontcentre.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2887.4349914868662!2d-79.38638461114502!3d43.639117403750205!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b352a8a12d2c9%3A0x747fe307c5654095!2sHarbourfront%20Centre!5e0!3m2!1sen!2sca!4v1755805004183!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Harbourfront Centre'
    """
  end
end
