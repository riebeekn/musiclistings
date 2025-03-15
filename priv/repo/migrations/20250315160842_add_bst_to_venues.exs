defmodule MusicListings.Repo.Migrations.AddBstToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('Berkeley Street Theatre', 'n/a', false, '26 Berkeley St', 'Toronto', 'Ontario', 'Cananda', 'M5A 2W3', 'https://www.canadianstage.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.8792904118545!2d-79.3639975!3d43.6506797!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb3b8eb82e77%3A0x9458fe10ac276ff!2sCanadian%20Stage%20(Berkeley%20Street%20Theatre)!5e0!3m2!1sen!2sca!4v1742055044121!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Berkeley Street Theatre'
    """
  end
end
