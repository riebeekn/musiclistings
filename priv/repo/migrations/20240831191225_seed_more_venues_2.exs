defmodule MusicListings.Repo.Migrations.SeedMoreVenues2 do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
    VALUES('Annabel''s Music Hall', 'AnnabelsParser', true, '200 Princes'' Blvd', 'Toronto', 'Ontario', 'Cananda', 'M6K 3C3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11550.994298243939!2d-79.4215827!3d43.6325917!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35871cb3b95b%3A0x26b0f1a1ab8bc82d!2sAnnabel&#39;s!5e0!3m2!1sen!2sca!4v1725131827867!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Bovine Sex Club', 'BovineParser', true, '542 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 2B5', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.10151946616!2d-79.4027839!3d43.6476403!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34dd8a6615a1%3A0x60070b9770e3d0d8!2sBovine%20Sex%20Club!5e0!3m2!1sen!2sca!4v1725135312849!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Drom Taberna', 'DromTabernaParser', true, '458 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 2A8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.9961244357!2d-79.3995908!3d43.6481885!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3589a68ca8c7%3A0x3d51621ef57fce99!2sDROM%20Taberna!5e0!3m2!1sen!2sca!4v1725206639948!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Annabel''s Music Hall'
    """

    execute """
    DELETE FROM venues WHERE name = 'Bovine Sex Club'
    """

    execute """
    DELETE FROM venues WHERE name = 'Drom Taberna'
    """
  end
end
