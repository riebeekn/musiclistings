defmodule MusicListingsSchema.SubmittedEvent do
  @moduledoc """
  Schema to represent a submitted event
  """
  use MusicListingsSchema.Schema

  @type t :: %__MODULE__{
          title: String.t(),
          venue: String.t(),
          date: Date.t(),
          time: String.t(),
          price: String.t(),
          url: String.t(),
          approved?: boolean(),
          inserted_at: DateTime.t()
        }

  schema "submitted_events" do
    field :title, :string
    field :venue, :string
    field :date, :date
    field :time, :string
    field :price, :string
    field :url, :string
    field :approved?, :boolean, source: :is_approved

    timestamps(updated_at: false)
  end
end
