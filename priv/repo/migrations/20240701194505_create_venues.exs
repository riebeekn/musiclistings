defmodule MusicListings.Repo.Migrations.CreateVenues do
  use Ecto.Migration

  def change do
    create table(:venues) do
      add :name, :string, null: false
      add :pull_events, :boolean, default: true
      add :parser_module_name, :string, null: false
    end
  end
end
