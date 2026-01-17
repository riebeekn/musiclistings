defmodule MusicListingsSchema.CrawlError do
  @moduledoc """
  Schema to represent a crawl error
  """
  use MusicListingsSchema.Schema

  schema "crawl_errors" do
    belongs_to :crawl_summary, MusicListingsSchema.CrawlSummary
    belongs_to :venue, MusicListingsSchema.Venue

    field :type, Ecto.Enum,
      values: [:parse_error, :no_events_error, :save_error, :invalid_parser_error]

    field :error, :string
    field :raw_event, :string

    timestamps(updated_at: false)
  end
end
