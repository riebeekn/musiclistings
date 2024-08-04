defmodule MusicListingsSchema.CrawlSummary do
  @moduledoc """
  Schema to represent a crawl summary
  """
  use MusicListingsSchema.Schema

  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.VenueCrawlSummary

  schema "crawl_summaries" do
    field :new, :integer
    field :updated, :integer
    field :duplicate, :integer
    field :ignored, :integer
    field :parse_errors, :integer

    has_many :venue_crawl_summaries, VenueCrawlSummary
    has_many :crawl_errors, CrawlError
    timestamps()
  end
end
