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

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Rockpile', 'RockpileParser', true, '5555 Dundas St W', 'Etobicoke', 'Ontario', 'Cananda', 'M9B 1B8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11551.572985172737!2d-79.5490453!3d43.6295808!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b37ee51e5a41f%3A0x14bcb9780c13ac79!2sThe%20Rockpile!5e0!3m2!1sen!2sca!4v1725207522674!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Hugh''s Room', 'HughsRoomParser', true, '296 Broadview Ave', 'Toronto', 'Ontario', 'Cananda', 'M4M 2G7', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11544.980882962212!2d-79.3522165!3d43.6638696!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b343741bfe88d%3A0xbaf96a390edf4cf7!2sHugh&#39;s%20Room%20Live!5e0!3m2!1sen!2sca!4v1725219837672!5m2!1sen!2sca')
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

    execute """
    DELETE FROM venues WHERE name = 'The Rockpile'
    """

    execute """
    DELETE FROM venues WHERE name = 'Hugh''s Room'
    """
  end
end
