defmodule MusicListingsSchema.EventFlag do
  @moduledoc """
  Schema to represent a listing quality problem raised against an event.

  Flags are raised by `MusicListings.Curation` after each crawl and worked
  through by an admin, who either soft-deletes the event or dismisses the flag.
  They are persisted rather than recomputed for the email so that an event
  judged fine stays judged - `dismissed_at` is what stops a legitimate listing
  being re-reported every night.

  A `:duplicate_event` flag describes a *pair*, and only one row is written for
  it: the flag hangs off the higher event id with `related_event_id` pointing at
  the lower.  Either side can be deleted to resolve it.
  """
  use MusicListingsSchema.Schema

  @type flag_type :: :non_event_title | :duplicate_event

  @type t :: %__MODULE__{
          event_id: pos_integer(),
          related_event_id: pos_integer() | nil,
          type: flag_type(),
          reason: String.t(),
          dismissed_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "event_flags" do
    belongs_to :event, MusicListingsSchema.Event
    belongs_to :related_event, MusicListingsSchema.Event

    field :type, Ecto.Enum, values: [:non_event_title, :duplicate_event]
    field :reason, :string
    field :dismissed_at, :utc_datetime

    timestamps()
  end
end
