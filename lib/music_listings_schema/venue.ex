defmodule MusicListingsSchema.Venue do
  @moduledoc """
  Schema to represent a venue
  """
  use MusicListingsSchema.Schema

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          pull_events?: boolean(),
          parser_module_name: String.t(),
          street: String.t(),
          city: String.t(),
          province: String.t(),
          country: String.t(),
          postal_code: String.t(),
          google_map_url: String.t(),
          website: String.t()
        }

  schema "venues" do
    field :name, :string
    field :pull_events?, :boolean, source: :pull_events
    field :parser_module_name, :string
    field :street, :string
    field :city, :string
    field :province, :string
    field :country, :string
    field :postal_code, :string
    field :google_map_url, :string
    field :website, :string
  end
end
