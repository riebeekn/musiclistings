defmodule MusicListings.Repo.Migrations.SeedMoreVenues8 do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Poetry Jazz Cafe', 'PoetryJazzCafeParser', true, '1078 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M6J 1H8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.848213554691!2d-79.4217503!3d43.6437563!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34c201443efb%3A0xcf876a6bbce0fc5a!2sPoetry%20Jazz%20Cafe!5e0!3m2!1sen!2sca!4v1725820040627!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('BSMT 254', 'Bsmt254Parser', true, '254 Lansdowne Ave', 'Toronto', 'Ontario', 'Cananda', 'M6H 3X9', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.429891630252!2d-79.4403135!3d43.6511336!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3527a93a3ea1%3A0x651b92467230216a!2sBSMT254!5e0!3m2!1sen!2sca!4v1725840487607!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Castro''s Lounge', 'CastrosLoungeParser', true, '2116 Queen St E', 'Toronto', 'Ontario', 'Cananda', 'M4E 1E2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11543.565828222401!2d-79.2951007!3d43.6712272!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc00c57ad4e3%3A0x94ce1628a0abe719!2sCastro&#39;s%20Lounge!5e0!3m2!1sen!2sca!4v1725841768852!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Primal Note Studios', 'PrimalNoteParser', true, '1141 Roselawn Ave', 'Toronto', 'Ontario', 'Cananda', 'M6B 1C5', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11538.142735414589!2d-79.4528966!3d43.6994155!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b336f407d7e47%3A0xe6a4329e43f056c4!2sPrimal%20Note%20Studios!5e0!3m2!1sen!2sca!4v1725843627917!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('CNE', 'CneParser', true, '100 Princes'' Blvd', 'Toronto', 'Ontario', 'Cananda', 'M6K 3C3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11550.517202053074!2d-79.4123625!3d43.6350739!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3528b87f1db3%3A0xa5da38e3b52ec273!2sExhibition%20Place!5e0!3m2!1sen!2sca!4v1725905594698!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Rivoli', 'RivoliParser', true, '334 Queen St W, Toronto', 'Toronto', 'Ontario', 'Cananda', 'M5V 2A2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.788791907098!2d-79.3948949!3d43.6492669!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34db21f97449%3A0x8e0b1d65ec2a33b0!2sRivoli%20Toronto!5e0!3m2!1sen!2sca!4v1725914021915!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Linsmore Tavern', 'LinsmoreParser', true, '1298 Danforth Ave Toronto', 'Toronto', 'Ontario', 'Cananda', 'M4J 1M6', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11541.464416203085!2d-79.3299873!3d43.6821517!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc7cabae5f21%3A0xf544c6555cbd3462!2sLinsmore%20Tavern!5e0!3m2!1sen!2sca!4v1725918178063!5m2!1sen!2sca')
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Poetry Jazz Cafe'
    """

    execute """
    DELETE FROM venues WHERE name = 'BSMT 254'
    """

    execute """
    DELETE FROM venues WHERE name = 'Castro''s Lounge'
    """

    execute """
    DELETE FROM venues WHERE name = 'Primal Note Studios'
    """

    execute """
    DELETE FROM venues WHERE name = 'CNE'
    """

    execute """
    DELETE FROM venues WHERE name = 'Rivoli'
    """

    execute """
    DELETE FROM venues WHERE name = 'Linsmore Tavern'
    """
  end
end
