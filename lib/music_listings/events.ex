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
  @default_page_size 100

  @spec list_events(list()) :: any()
  def list_events(opts \\ []) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    venue_id = Keyword.get(opts, :venue_id, nil)

    today = DateHelpers.now() |> DateHelpers.to_eastern_date()

    pagination_result =
      Event
      |> where([event], event.date >= ^today)
      |> maybe_filter_by_venue(venue_id)
      |> order_by([:date, :time, :title])
      |> preload(:venue)
      |> Repo.paginate(page: page, page_size: page_size)

    grouped_events =
      pagination_result.entries
      |> Enum.group_by(& &1.date)
      |> Enum.sort_by(fn {date, _events} -> date end, Date)

    %PagedEvents{
      events: grouped_events,
      current_page: pagination_result.page_number,
      total_pages: pagination_result.total_pages
    }
  end

  defp maybe_filter_by_venue(query, nil), do: query

  defp maybe_filter_by_venue(query, venue_id) when is_integer(venue_id) do
    query
    |> where([event], event.venue_id == ^venue_id)
  end
end
