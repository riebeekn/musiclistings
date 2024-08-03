defmodule MusicListingsSchema.IgnoredEvent do
  @moduledoc """
  Schema to represent an ignored event
  """
  use Ecto.Schema

  @timestamps_opts [
    type: :utc_datetime_usec
  ]
  schema "ignored_events" do
    field :ignored_event_id, :string

    belongs_to :venue, MusicListingsSchema.Venue

    timestamps()
  end
end
