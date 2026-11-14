defmodule MusicListings.Repo.Migrations.AddLulaLoungeToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Lula Lounge', 'LulaLoungeParser', true, '1585 Dundas St W', 'Toronto', 'Ontario', 'Canada', 'M6K 1T9', 'https://www.lula.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.925049382917!2d-79.4345802!3d43.64972770000001!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34518eda9353%3A0xe8acfa669c5f31d8!2sLula%20Lounge!5e0!3m2!1sen!2sus!4v1794681461611!5m2!1sen!2sus')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Lula Lounge'
    """)
  end
end
