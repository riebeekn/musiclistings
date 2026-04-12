defmodule MusicListings.Repo.Migrations.AddCestWhatToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('C''est What', 'CestWhatParser', true, '67 Front St E', 'Toronto', 'Ontario', 'Canada', 'M5E 1B5', 'https://cestwhat.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.9851356616864!2d-79.37341359999999!3d43.6484776!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb31e100d5df%3A0x8b2c7f9db075df87!2zQ-KAmWVzdCBXaGF0PyBJbmMu!5e0!3m2!1sen!2sca!4v1769452558852!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'C''est What'
    """)
  end
end
