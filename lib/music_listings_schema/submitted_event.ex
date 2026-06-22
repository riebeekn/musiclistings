defmodule MusicListingsSchema.SubmittedEvent do
  @moduledoc """
  Schema to represent a submitted event
  """
  use MusicListingsSchema.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          title: String.t(),
          venue: String.t(),
          date: Date.t(),
          time: String.t(),
          price: String.t(),
          url: String.t(),
          approved?: boolean(),
          deleted_at: DateTime.t() | nil,
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
    field :deleted_at, :utc_datetime

    timestamps(updated_at: false)
  end

  @doc """
  Builds a changeset for creating or updating a submitted event.
  """
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(submitted_event, attrs) do
    submitted_event
    |> cast(attrs, [:title, :venue, :date, :time, :price, :url])
    |> validate_required([:title, :venue, :date])
  end
end
