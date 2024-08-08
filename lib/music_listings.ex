defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  alias MusicListings.Crawler
  alias MusicListings.Events
  alias MusicListingsSchema.IgnoredEvent

  require Logger

  @spec data_last_updated_on :: String.t()
  defdelegate data_last_updated_on, to: Crawler

  @spec ignore_crawl_error(pos_integer()) :: IgnoredEvent
  defdelegate ignore_crawl_error(crawl_error_id), to: Crawler

  @spec list_events(list()) :: any()
  defdelegate list_events(opts \\ []), to: Events
end
