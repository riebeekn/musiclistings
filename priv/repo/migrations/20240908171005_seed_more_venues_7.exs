defmodule MusicListings.Repo.Migrations.SeedMoreVenues7 do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Handlebar', 'HandlebarParser', true, '159 Augusta Ave', 'Toronto', 'Ontario', 'Cananda', 'M5T 2L4', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.087187817495!2d-79.4011013!3d43.652916!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34c2f3a641cb%3A0x2df0f77b94e70616!2sHandlebar!5e0!3m2!1sen!2sca!4v1725815477967!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Handlebar'
    """
  end
end
