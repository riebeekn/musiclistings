defmodule MusicListings.Repo.Migrations.AddBadAngelToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Bad Angel', 'BadAngelParser', true, '1615 Dundas St W', 'Toronto', 'Ontario', 'Canada', 'M6K 1T9', 'https://www.badangelbar.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.923520892339!2d-79.4353647!3d43.649759499999995!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35095c995e51%3A0xe1c26cff5b5c6c19!2sThe%20Bad%20Angel!5e0!3m2!1sen!2sca!4v1794088797684!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Bad Angel'
    """)
  end
end
