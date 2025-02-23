defmodule MusicListings.Repo.Migrations.AddUniqueIndexToVenueName do
  use Ecto.Migration

  def change do
    create unique_index(:venues, [:name])
  end
end
