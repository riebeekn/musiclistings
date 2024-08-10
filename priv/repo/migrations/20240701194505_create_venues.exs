defmodule MusicListings.Repo.Migrations.CreateVenues do
  use Ecto.Migration

  def change do
    create table(:venues) do
      add :name, :string, null: false
      add :pull_events, :boolean, default: true
      add :parser_module_name, :string, null: false
      add :street, :string, null: false
      add :city, :string, null: false
      add :province, :string, null: false
      add :country, :string, null: false
      add :postal_code, :string, null: false
      add :google_map_url, :text
    end
  end
end
