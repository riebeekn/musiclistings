defmodule MusicListings.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :external_id, :string, null: false
      add :title, :string, null: false
      add :headliner, :string, null: false
      add :openers, {:array, :string}
      add :date, :date, null: false
      # TODO: should we have a time type?  i.e. is this the door time
      # or the show time?
      add :time, :string, null: false
      # TODO: should this be split out more?  for instance some shows
      # have price ranges, i.e. $25.00 - $45.00 (plus service fees)
      add :price, :string, null: false
      add :age_restriction, :string
      add :source_url, :string
      add :ticket_url, :string, size: 2048

      add :venue_id, references(:venues), null: false

      timestamps()
    end

    create unique_index(:events, [:external_id, :venue_id])
  end
end
