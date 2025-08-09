defmodule MusicListings.Repo.Migrations.AddSoundGarageToVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
      VALUES('The Sound Garage', 'SoundGarageParser', true, '165 Geary Ave', 'Toronto', 'Ontario', 'Canada', 'M6H 2B8', 'https://www.bloodbrothersbrewing.com/pages/the-sound-garage-165-geary-ave', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.9572215830854!2d-79.4361871!3d43.66985950000001!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3580ae326d49%3A0x8b970780cf634cda!2sThe%20Sound%20Garage%20at%20Blood%20Brothers%20Brewing!5e0!3m2!1sen!2sca!4v1754762173642!5m2!1sen!2sca')
      ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    execute """
    DELETE FROM venues WHERE name = 'The Sound Garage'
    """
  end
end
