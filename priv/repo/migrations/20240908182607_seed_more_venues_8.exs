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
  end
end
