defmodule MusicListingsSchema.Event do
  @moduledoc """
  Schema to represent an event
  """
  use MusicListingsSchema.Schema

  @type t :: %__MODULE__{
          external_id: String.t(),
          title: String.t(),
          headliner: String.t(),
          openers: [String.t()],
          date: Date.t(),
          time: Time.t(),
          price_format: :fixed | :free | :range | :unknown | :variable,
          price_lo: Decimal.t(),
          price_hi: Decimal.t(),
          age_restriction: :all_ages | :eighteen_plus | :nineteen_plus | :unknown,
          ticket_url: String.t(),
          details_url: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "events" do
    field :external_id, :string
    field :title, :string
    field :headliner, :string
    field :openers, {:array, :string}
    field :date, :date
    field :time, :time
    field :price_format, Ecto.Enum, values: [:fixed, :free, :range, :unknown, :variable]
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
