defmodule MusicListingsSchema.Venue do
  @moduledoc """
  Schema to represent a venue
  """
  use Ecto.Schema

  schema "venues" do
    field :name, :string
    field :pull_events?, :boolean, source: :pull_events
    field :parser_module_name, :string
  end
end
