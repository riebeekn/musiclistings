defmodule MusicListings.Repo.Migrations.UpdateEventOpenersSize do
  use Ecto.Migration

  def up do
    alter table(:events) do
      modify :openers, {:array, :text}, null: false
    end
  end

  def down do
    alter table(:events) do
      modify :openers, {:array, :string}, null: false
    end
  end
end
