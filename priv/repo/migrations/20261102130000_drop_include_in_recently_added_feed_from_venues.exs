defmodule MusicListings.Repo.Migrations.DropIncludeInRecentlyAddedFeedFromVenues do
  use Ecto.Migration

  # The "New This Week" rail was the only reader of this column. The schema field
  # was removed a deploy earlier, so no running instance selects it any more and
  # it is safe to drop (migrations run on boot, while the old instance still serves).

  def change do
    alter table(:venues) do
      remove :include_in_recently_added_feed, :boolean, null: false, default: false
    end
  end
end
