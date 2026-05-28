defmodule MusicListings.Repo.Migrations.AddIncludeInRecentlyAddedFeedToVenues do
  use Ecto.Migration

  def change do
    alter table(:venues) do
      add :include_in_recently_added_feed, :boolean, null: false, default: false
    end
  end
end
