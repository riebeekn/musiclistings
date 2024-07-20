defmodule MusicListingsSchema.CrawlError do
  @moduledoc """
  Schema to represent a crawl error
  """
  use Ecto.Schema

  @timestamps_opts [
    type: :utc_datetime_usec
  ]
  schema "crawl_errors" do
    belongs_to :crawl_summary, MusicListingsSchema.CrawlSummary
    belongs_to :venue, MusicListingsSchema.Venue
    field :type, Ecto.Enum, values: [:parse_error, :save_error]
    field :error, :string
    field :raw_event, :string

    timestamps(updated_at: false)
  end
end
