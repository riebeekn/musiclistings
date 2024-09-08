defmodule MusicListings.Repo.Migrations.SeedMoreVenues8 do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Poetry Jazz Cafe', 'PoetryJazzCafeParser', true, '1078 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M6J 1H8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.848213554691!2d-79.4217503!3d43.6437563!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34c201443efb%3A0xcf876a6bbce0fc5a!2sPoetry%20Jazz%20Cafe!5e0!3m2!1sen!2sca!4v1725820040627!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Poetry Jazz Cafe'
    """
  end
end
