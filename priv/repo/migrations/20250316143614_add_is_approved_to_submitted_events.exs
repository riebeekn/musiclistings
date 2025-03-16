defmodule MusicListings.Repo.Migrations.AddIsApprovedToSubmittedEvents do
  use Ecto.Migration

  def change do
    alter table(:submitted_events) do
      add :is_approved, :boolean, null: false, default: false
    end
  end
end
