defmodule MusicListingsSchema.AnalyticsEvent do
  @moduledoc """
  Schema to represent a first-party product analytics event (e.g. a feature
  impression or click). Intentionally generic: `name` identifies the event and
  `metadata` holds an arbitrary payload, so the same table can serve future
  events beyond the "New This Week" rail.
  """
  use MusicListingsSchema.Schema

  @type t :: %__MODULE__{
          name: String.t(),
          metadata: map(),
          inserted_at: DateTime.t()
        }

  schema "analytics_events" do
    field :name, :string
    field :metadata, :map, default: %{}

    timestamps(updated_at: false)
  end
end
