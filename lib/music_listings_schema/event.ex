defmodule MusicListingsSchema.Event do
  @moduledoc """
  Schema to represent an event
  """
  use Ecto.Schema

  @timestamps_opts [
    type: :utc_datetime_usec
  ]
  schema "events" do
    field :external_id, :string
    field :title, :string
    field :headliner, :string
    field :openers, {:array, :string}
    field :date, :date
    field :time, :time
    field :price_format, Ecto.Enum, values: [:fixed, :range, :tbd, :variable]
    field :price_lo, :decimal
    field :price_hi, :decimal
    field :age_restriction, Ecto.Enum, values: [:all_ages, :nineteen_plus, :tbd]
    field :source_url, :string
    field :ticket_url, :string

    belongs_to :venue, MusicListingsSchema.Venue

    timestamps()
  end
end
