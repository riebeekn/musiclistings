defmodule MusicListingsSchema.VenueCrawlSummary do
  @moduledoc """
  Schema to represent a venue summary of a crawl
  """
  use Ecto.Schema

  @timestamps_opts [
    type: :utc_datetime_usec
  ]
  schema "venue_crawl_summaries" do
    belongs_to :venue, MusicListingsSchema.Venue
    belongs_to :crawl_summary, MusicListingsSchema.CrawlSummary

    field :new, :integer
    field :updated, :integer
    field :duplicate, :integer
    field :parse_errors, :integer

    timestamps(updated_at: false)
  end
end
