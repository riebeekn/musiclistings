defmodule MusicListings.Repo.Migrations.AddEmmetRayToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('The Emmet Ray', 'EmmetRayParser', true, '924 College St', 'Toronto', 'Ontario', 'Cananda', 'M6H 1A4', 'https://www.theemmetray.com/', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.89508498378!2d-79.4256873!3d43.6539151!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b345808a55cc3%3A0xe3e2f9c598b9cc35!2sThe%20Emmet%20Ray%20Whisky%20Jazz%20Bar!5e0!3m2!1sen!2sca!4v1728754729759!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'The Emmet Ray'
    """
  end
end
