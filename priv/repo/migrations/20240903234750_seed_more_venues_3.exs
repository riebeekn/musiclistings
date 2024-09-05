defmodule MusicListings.Repo.Migrations.SeedMoreVenues3 do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
    VALUES('Supermarket', 'SupermarketParser', true, '268 Augusta Ave', 'Toronto', 'Ontario', 'Cananda', 'M5T 2L9', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11586.463560701393!2d-79.4031896387427!3d43.65660699934145!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34ea09affeaf%3A0xbd318e645db765c8!2sSupermarket%20Bar%20and%20Variety!5e0!3m2!1sen!2sca!4v1725407414650!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Supermarket'
    """
  end
end
