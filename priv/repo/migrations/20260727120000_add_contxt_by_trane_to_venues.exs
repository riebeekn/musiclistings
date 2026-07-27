defmodule MusicListings.Repo.Migrations.AddContxtByTraneToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('CONTXT by Trane', 'ContxtByTraneParser', true, '254 Lansdowne Avenue', 'Toronto', 'Ontario', 'Canada', 'M6H 3X9', 'https://contxtbytrane.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d1443.3930522383544!2d-79.4395918876274!3d43.65261835077033!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35fa17c32d23%3A0xae33b3bf85dfb3d2!2sCONTXT%20by%20Trane!5e0!3m2!1sen!2sca!4v1785178248170!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'CONTXT by Trane'
    """)
  end
end
