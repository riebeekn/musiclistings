defmodule MusicListings.Repo.Migrations.AddOnlyCafeToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('The Only Cafe', 'OnlyCafeParser', true, '966 Danforth Avenue', 'Toronto', 'Ontario', 'Canada', 'M4J 1L9', 'https://www.theonlycafe.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.4472041073686!2d-79.3380081!3d43.680465399999996!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc8700dd4af3%3A0x8080c6a37a8122c2!2sThe%20Only%20Cafe!5e0!3m2!1sen!2sca!4v1783732234232!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'The Only Cafe'
    """)
  end
end
