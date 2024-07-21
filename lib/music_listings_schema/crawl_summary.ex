defmodule MusicListingsSchema.CrawlSummary do
  @moduledoc """
  Schema to represent a crawl summary
  """
  use Ecto.Schema

  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.VenueCrawlSummary

  @timestamps_opts [
    type: :utc_datetime_usec
  ]
  schema "crawl_summaries" do
    field :new, :integer
    field :updated, :integer
    field :duplicate, :integer
    field :parse_errors, :integer

    has_many :venue_crawl_summaries, VenueCrawlSummary
    has_many :crawl_errors, CrawlError
    timestamps()
  end
end
