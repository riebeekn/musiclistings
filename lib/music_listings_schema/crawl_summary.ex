defmodule MusicListingsSchema.CrawlSummary do
  @moduledoc """
  Schema to represent a crawl summary
  """
  use MusicListingsSchema.Schema

  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.VenueCrawlSummary

  @type t :: %__MODULE__{
          new: pos_integer(),
          updated: pos_integer(),
          duplicate: pos_integer(),
          ignored: pos_integer(),
          parse_errors: pos_integer(),
          completed_at: DateTime.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "crawl_summaries" do
    field :new, :integer
    field :updated, :integer
    field :duplicate, :integer
    field :ignored, :integer
    field :parse_errors, :integer
    field :completed_at, :utc_datetime

    has_many :venue_crawl_summaries, VenueCrawlSummary
    has_many :crawl_errors, CrawlError
    timestamps()
  end
end
