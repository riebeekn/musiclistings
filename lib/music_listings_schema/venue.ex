defmodule MusicListingsSchema.Venue do
  use Ecto.Schema

  schema "venues" do
    field :name, :string
  end
end
