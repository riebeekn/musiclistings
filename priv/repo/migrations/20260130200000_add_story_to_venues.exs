defmodule MusicListings.Repo.Migrations.AddStoryToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('Story Toronto', 'StoryParser', true, '214 Adelaide St W', 'Toronto', 'Ontario', 'Canada', 'M5H 1W7', 'https://www.storytoronto.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.979555352435!2d-79.3876025!3d43.64859369999999!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35002fe66789%3A0x79d3b1e4cff9e53d!2sStory%20Toronto!5e0!3m2!1sen!2sca!4v1769806078016!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Story Toronto'
    """
  end
end
