defmodule MusicListings.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :external_id, :string, null: false
      add :title, :string, null: false
      add :headliner, :string
      add :openers, {:array, :string}
      add :date, :date
      add :time, :time
      add :price_format, :string, null: false
      add :price_lo, :decimal
      add :price_hi, :decimal
      add :age_restriction, :string, null: false
      add :ticket_url, :string, size: 2048
      add :details_url, :string, size: 2048

      add :venue_id, references(:venues), null: false

      timestamps()
    end

    create unique_index(:events, [:external_id, :venue_id])
  end
end
