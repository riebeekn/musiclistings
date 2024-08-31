defmodule MusicListings.Repo.Migrations.SeedMoreVenues2 do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Annabel''s Music Hall', 'AnnabelsParser', true, '200 Princes'' Blvd', 'Toronto', 'Ontario', 'Cananda', 'M6K 3C3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11550.994298243939!2d-79.4215827!3d43.6325917!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35871cb3b95b%3A0x26b0f1a1ab8bc82d!2sAnnabel&#39;s!5e0!3m2!1sen!2sca!4v1725131827867!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Annabel''s Music Hall'
    """
  end
end
