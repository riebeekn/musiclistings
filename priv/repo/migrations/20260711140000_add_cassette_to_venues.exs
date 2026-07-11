defmodule MusicListings.Repo.Migrations.AddCassetteToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Cassette', 'CassetteParser', true, '1214 Queen St W', 'Toronto', 'Ontario', 'Canada', 'M6J 1J6', 'https://www.cassetteto.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d1443.594573510247!2d-79.42628071646347!3d43.64423291343019!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35f65ce0dd35%3A0xe8fd45d1876dfb6!2sCassette!5e0!3m2!1sen!2sca!4v1783779459215!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Cassette'
    """)
  end
end
