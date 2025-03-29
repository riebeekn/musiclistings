defmodule MusicListings.Repo.Migrations.RemoveDakotaTavern do
  use Ecto.Migration

  def up do
    execute """
      DELETE FROM crawl_errors
      USING venues
      WHERE crawl_errors.venue_id = venues.id
      AND venues.name = 'The Dakota Tavern'
    """

    execute """
      DELETE FROM venue_crawl_summaries
      USING venues
      WHERE venue_crawl_summaries.venue_id = venues.id
      AND venues.name = 'The Dakota Tavern'
    """

    execute """
      DELETE FROM venues WHERE name = 'The Dakota Tavern';
    """
  end

  def down do
  end
end
