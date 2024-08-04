defmodule MusicListingsSchema.IgnoredEvent do
  @moduledoc """
  Schema to represent an ignored event
  """
  use MusicListingsSchema.Schema

  schema "ignored_events" do
    field :ignored_event_id, :string

    belongs_to :venue, MusicListingsSchema.Venue

    timestamps()
  end
end
