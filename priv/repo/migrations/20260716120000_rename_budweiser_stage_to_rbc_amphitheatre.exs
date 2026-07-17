defmodule MusicListings.Repo.Migrations.RenameBudweiserStageToRbcAmphitheatre do
  use Ecto.Migration

  # Budweiser Stage (formerly Molson Amphitheatre) was renamed to RBC Amphitheatre.
  # Same LiveNation venue (KovZpZAEkkIA) - only the display name and website slug
  # change, so BudweiserStageParser keeps working untouched.
  def up do
    execute("""
    UPDATE venues
    SET name = 'RBC Amphitheatre',
        website = 'https://www.livenation.com/venue/KovZpZAEkkIA/rbc-amphitheatre-events'
    WHERE name = 'Budweiser Stage'
    """)
  end

  def down do
    execute("""
    UPDATE venues
    SET name = 'Budweiser Stage',
        website = 'https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events'
    WHERE name = 'RBC Amphitheatre'
    """)
  end
end
