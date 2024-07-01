defmodule MusicListingsSchema.Event do
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
    # TODO: should we have a time type?  i.e. is this the door time
    # or the show time?
    field :time, :string
    # TODO: should this be split out more?  for instance some shows
    # have price ranges, i.e. $25.00 - $45.00 (plus service fees)
    field :price, :string
    field :age_restriction, Ecto.Enum, values: [:all_ages, :nineteen_plus]
    field :original_url, :string
    field :ticket_url, :string

    belongs_to :venue, MusicListingsSchema.Venue

    timestamps()
  end
end
