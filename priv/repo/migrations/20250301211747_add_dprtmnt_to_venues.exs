defmodule MusicListings.Repo.Migrations.AddDprtmntToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('DPRTMNT', 'DprtmntParser', true, '473 Adelaide St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 1T1', 'https://dprtmnt.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2887.1424993469227!2d-79.3998476!3d43.64520350000001!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b350b14cd9e07%3A0xe608aff75e03ec24!2sDPRTMNT!5e0!3m2!1sen!2sca!4v1740863980220!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'DPRTMNT'
    """
  end
end
