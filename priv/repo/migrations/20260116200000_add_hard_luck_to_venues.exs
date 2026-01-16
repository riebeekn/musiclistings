defmodule MusicListings.Repo.Migrations.AddHardLuckToVenues do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Hard Luck Bar', 'HardLuckParser', 'true', '772 Dundas St W', 'Toronto', 'Ontario', 'Canada', 'M6J 1V3', 'https://hardluckbar.ca', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d1443.3978867902867!2d-79.4079207092621!3d43.65241719683323!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34e8a4ceb52d%3A0xb933c896eb08a9a4!2sHard%20Luck%20Bar!5e0!3m2!1sen!2sca!4v1768596264352!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'Hard Luck Bar'
    """
  end
end
