defmodule MusicListingsSchema.Venue do
  @moduledoc """
  Schema to represent a venue
  """
  use Ecto.Schema

  schema "venues" do
    field :name, :string
  end
end
