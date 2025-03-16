defmodule MusicListings.Events do
  @moduledoc """
  Context module for event related functionality
  """
  import Ecto.Query

  alias Ecto.Changeset
  alias MusicListings.Accounts.User
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsUtilities.DateHelpers

  @default_page 1
  @default_page_size 100

  @type list_events_opts ::
          {:page, pos_integer()}
          | {:page_size, pos_integer()}
          | {:venue_ids,
             list(pos_integer())
             | {:order_by, list(atom())}}
  @spec list_events(list(list_events_opts)) :: PagedEvents.t()
  def list_events(opts \\ []) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    venue_ids = Keyword.get(opts, :venue_ids, [])
    order_by_fields = Keyword.get(opts, :order_by, [:date, :title])

    today = DateHelpers.now() |> DateHelpers.to_eastern_date()

    pagination_result =
      Event
      |> where([event], event.date >= ^today)
      |> where([event], is_nil(event.deleted_at))
      |> maybe_filter_by_venues(venue_ids)
      |> order_by(^order_by_fields)
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

  defp maybe_filter_by_venues(query, []), do: query

  defp maybe_filter_by_venues(query, venue_ids) when is_list(venue_ids) do
    query
    |> where([event], event.venue_id in ^venue_ids)
  end

  def list_submitted_events(opts \\ []) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)

    pagination_result =
      SubmittedEvent
      |> order_by(desc: :inserted_at, asc: :title)
      |> Repo.paginate(page: page, page_size: page_size)

    %PagedEvents{
      events: pagination_result.entries,
      current_page: pagination_result.page_number,
      total_pages: pagination_result.total_pages
    }
  end

  @spec delete_event(User | nil, pos_integer()) :: {:ok, Event} | {:error, :not_allowed}
  def delete_event(%User{role: :admin}, event_id) do
    Event
    |> Repo.get!(event_id)
    |> Changeset.change(%{deleted_at: DateHelpers.now()})
    |> Repo.update()
  end

  def delete_event(_user, _event_id) do
    {:error, :not_allowed}
  end

  def fetch_submitted_event(submitted_event_id) do
    SubmittedEvent
    |> Repo.get(submitted_event_id)
    |> case do
      nil -> {:error, :submitted_event_not_found}
      submitted_event -> {:ok, submitted_event}
    end
  end
end
