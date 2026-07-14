defmodule MusicListings.Repo.Migrations.IndexAnalyticsEventsVisitorId do
  use Ecto.Migration

  # The weekly surface-funnel report groups and dedupes on the visitor id, which
  # lives inside the free-form `metadata` jsonb rather than its own column, so it
  # needs a functional index to stay cheap as the table grows.
  def change do
    create index(:analytics_events, ["(metadata->>'visitor_id')"],
             name: :analytics_events_visitor_id_index
           )
  end
end
