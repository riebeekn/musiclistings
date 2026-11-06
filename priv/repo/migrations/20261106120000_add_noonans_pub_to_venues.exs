defmodule MusicListings.Repo.Migrations.AddNoonansPubToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Noonan''s Pub', 'NoonansParser', true, '141 Danforth Ave', 'Toronto', 'Ontario', 'Canada', 'M4K 1N2', 'https://noonanspub.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.6444972236995!2d-79.3573863!3d43.67636290000001!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc9ff39fee3d%3A0x1b658dda87dd947!2sNoonan''s!5e0!3m2!1sen!2sca!4v1794004238675!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Noonan''s Pub'
    """)
  end
end
