defmodule MusicListings.Repo.Migrations.SeedMoreVenues9 do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Meridian Hall', 'MeridianHallParser', true, '1 Front St E', 'Toronto', 'Ontario', 'Cananda', 'M5E 1B2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.287621206979!2d-79.3760205!3d43.6466723!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb2db063a1b1%3A0x40afbfba1f58eda2!2sMeridian%20Hall!5e0!3m2!1sen!2sca!4v1726519195569!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('St. Lawrence Centre for the Arts', 'StLawrenceArtsCentreParser', true, '27 Front St E', 'Toronto', 'Ontario', 'Cananda', 'M5E 1B4', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.122148468256!2d-79.3753073!3d43.647533!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb2dc4a888d7%3A0x8c74a6c134d2b31d!2sSt.%20Lawrence%20Centre%20for%20the%20Arts!5e0!3m2!1sen!2sca!4v1726619500975!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Meridian Hall'
    """

    execute """
    DELETE FROM venues WHERE name = 'St. Lawrence Centre for the Arts'
    """
  end
end