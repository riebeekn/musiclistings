defmodule MusicListingsSchema.CrawlSummary do
  @moduledoc """
  Schema to represent a crawl summary
  """
  use Ecto.Schema

  @timestamps_opts [
    type: :utc_datetime_usec
  ]
  schema "crawl_summaries" do
    field :new, :integer
    field :updated, :integer
    field :duplicate, :integer
    field :parse_errors, :integer

    timestamps()
  end
end
