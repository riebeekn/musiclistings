defmodule MusicListings.Events do
  @moduledoc """
  Context module for event related functionality
  """
  import Ecto.Query

  alias MusicListings.Events.PagedEvents
  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsUtilities.DateHelpers

  @default_page 1
  @default_page_size 10

  @spec list_events(list()) :: any()
  def list_events(opts \\ []) do
    page = opts |> Keyword.get(:page, @default_page)
    page_size = opts |> Keyword.get(:page_size, @default_page_size)

    today = DateHelpers.now() |> DateHelpers.to_eastern_date()

    pagination_result =
      Event
      |> where([event], event.date >= ^today)
      |> order_by([:date, :title])
      |> preload(:venue)
      |> Repo.paginate(page: page, page_size: page_size)

    grouped_events =
      pagination_result
      |> Enum.group_by(& &1.date)

    %PagedEvents{
      events: grouped_events,
      current_page: pagination_result.page_number,
      total_pages: pagination_result.total_pages
    }
  end
end
