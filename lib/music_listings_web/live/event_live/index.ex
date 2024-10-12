defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    venues = MusicListings.list_venues()

    socket =
      socket
      |> assign(:venues, venues)
      |> assign(:venue_filtering_form, to_form(%{}))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    venue_ids = socket.assigns[:venue_ids] || []

    case validate(:index, params) do
      {:ok, normalized_params} ->
        paged_events =
          MusicListings.list_events(
            page: normalized_params[:page],
            venue_ids: venue_ids
          )

        socket = update_socket_assigns(socket, paged_events, venue_ids)

        {:noreply, socket}

      _error ->
        {:noreply, push_navigate(socket, to: ~p"/events")}
    end
  end

  @impl true
  def handle_event("venue-filter-selected", venues_filter, socket) do
    venue_ids =
      venues_filter
      |> Map.keys()
      |> Enum.filter(fn key ->
        case Integer.parse(key) do
          :error -> false
          _is_venue_id -> true
        end
      end)

    paged_events =
      MusicListings.list_events(page: socket.assigns[:current_page], venue_ids: venue_ids)

    socket = update_socket_assigns(socket, paged_events, venue_ids)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear-venue-filtering", _params, socket) do
    venue_ids = []

    paged_events =
      MusicListings.list_events(page: socket.assigns[:current_page], venue_ids: venue_ids)

    socket = update_socket_assigns(socket, paged_events, venue_ids)

    {:noreply, socket}
  end

  defp update_socket_assigns(socket, paged_events, venue_ids) do
    socket
    |> assign(:events, paged_events.events)
    |> assign(:current_page, paged_events.current_page)
    |> assign(:total_pages, paged_events.total_pages)
    |> assign(:venue_ids, venue_ids)
  end

  defparams :index do
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-between mb-8 sm:mb-4 -mt-2">
      <.venue_filter for={@venue_filtering_form} venues={@venues} venue_ids={@venue_ids} />
      <.button_link label="Submit an event" url={~p"/events/new"} icon_name="hero-arrow-right" />
    </div>

    <.venue_filter_status venue_ids={@venue_ids} />

    <.events_list events={@events} />

    <div class="mt-6 pt-6 border-t border-zinc-700">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    </div>
    """
  end
end
