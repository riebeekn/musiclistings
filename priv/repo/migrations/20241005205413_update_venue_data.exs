defmodule MusicListings.Repo.Migrations.UpdateVenueData do
  use Ecto.Migration

  def up do
    execute """
    UPDATE venues SET google_map_url = 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11544.702064386196!2d-79.4095028!3d43.6653194!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3493e5c2a6cb%3A0x9da808d57162072!2sLee&#39;s%20Palace!5e0!3m2!1sen!2sca!4v1728161762716!5m2!1sen!2sca' WHERE name = 'Lee''s Palace'
    """

    execute """
    UPDATE venues SET website = 'https://greatcanadian.com/destinations/ontario/toronto' WHERE name = 'Great Canadian Casino Resort Toronto'
    """

    execute """
    UPDATE venues SET website = 'https://www.tolive.com/Meridian-Arts-Centre' WHERE name = 'Meridian Arts Centre'
    """

    execute """
    UPDATE venues SET website = 'https://www.tolive.com/St-Lawrence-Centre-for-the-Arts' WHERE name = 'St. Lawrence Centre for the Arts'
    """

    execute """
    UPDATE venues SET website = 'https://www.tolive.com/Meridian-Hall' WHERE name = 'Meridian Hall'
    """
  end

  def down do
  end
end
