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
    field :price_format, Ecto.Enum, values: [:fixed, :range, :unknown, :variable]
    field :price_lo, :decimal
    field :price_hi, :decimal

    field :age_restriction, Ecto.Enum,
      values: [:all_ages, :eighteen_plus, :nineteen_plus, :unknown]

    field :ticket_url, :string
    field :details_url, :string

    belongs_to :venue, MusicListingsSchema.Venue

    timestamps()
  end

  def changeset(attrs, event \\ %__MODULE__{}) do
    event
    |> Ecto.Changeset.cast(attrs, [
      :external_id,
      :venue_id,
      :title,
      :headliner,
      :openers,
      :date,
      :time,
      :price_format,
      :price_lo,
      :price_hi,
      :age_restriction,
      :ticket_url,
      :details_url
    ])
  end
end
