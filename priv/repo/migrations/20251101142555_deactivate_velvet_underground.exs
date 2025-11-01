defmodule MusicListings.Repo.Migrations.DeactivateVelvetUnderground do
  use Ecto.Migration

  def up do
    # Delete all records associated with Velvet Underground venue
    # Must be done in order due to foreign key constraints

    # Delete crawl errors
    execute """
      DELETE FROM crawl_errors
      WHERE venue_id IN (
        SELECT id FROM venues WHERE parser_module_name = 'VelvetUndergroundParser'
      )
    """

    # Delete ignored events
    execute """
      DELETE FROM ignored_events
      WHERE venue_id IN (
        SELECT id FROM venues WHERE parser_module_name = 'VelvetUndergroundParser'
      )
    """

    # Delete events
    execute """
      DELETE FROM events
      WHERE venue_id IN (
        SELECT id FROM venues WHERE parser_module_name = 'VelvetUndergroundParser'
      )
    """

    # Delete venue crawl summaries
    execute """
      DELETE FROM venue_crawl_summaries
      WHERE venue_id IN (
        SELECT id FROM venues WHERE parser_module_name = 'VelvetUndergroundParser'
      )
    """

    # Delete the Velvet Underground venue
    execute """
      DELETE FROM venues
      WHERE parser_module_name = 'VelvetUndergroundParser'
    """
  end

  def down do
    # Re-insert the Velvet Underground venue
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Velvet Underground', 'VelvetUndergroundParser', false, '508 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 2B3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.051475222872!2d-79.4015411!3d43.6479006!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34dd960a0175%3A0xa15eac3271fffc93!2sVelvet%20Underground!5e0!3m2!1sen!2sca!4v1723164988781!5m2!1sen!2sca')
    """
  end
end
