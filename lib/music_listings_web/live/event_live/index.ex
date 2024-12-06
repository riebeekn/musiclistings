defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    venue_ids = get_venue_ids_in_local_storage(socket)

    venues = MusicListings.list_venues(restrict_to_pulled_venues?: false)

    socket
    |> assign(:venues, venues)
    |> assign(:venue_ids, venue_ids)
    |> assign(:venue_filtering_form, to_form(%{}))
    |> ok()
  end

  defp get_venue_ids_in_local_storage(socket) do
    socket
    |> get_connect_params()
    |> case do
      %{"venue_ids" => venue_ids} ->
        if is_binary(venue_ids) do
          venue_ids
          |> String.split(",")
          |> filter_venue_ids()
        else
          []
        end

      _default ->
        []
    end
  end

  defp filter_venue_ids(venue_ids) do
    Enum.filter(venue_ids, fn venue_id ->
      case Integer.parse(venue_id) do
        {_valid_integer, ""} -> true
        _non_integer -> false
      end
    end)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      venue_ids = socket.assigns[:venue_ids] || []

      case validate(:index, params) do
        {:ok, normalized_params} ->
          paged_events =
            MusicListings.list_events(
              page: normalized_params[:page],
              venue_ids: venue_ids
            )

          socket
          |> update_socket_assigns(paged_events, venue_ids)
          |> assign(:loading, false)
          |> noreply()

        _error ->
          socket
          |> push_navigate(to: ~p"/events")
          |> noreply()
      end
    else
      socket
      |> assign(:events, [])
      |> assign(:current_page, 1)
      |> assign(:total_pages, 0)
      |> assign(:loading, true)
      |> noreply()
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

    socket
    |> update_socket_assigns(paged_events, venue_ids)
    |> push_event("saveVenueFilterIdsToLocalStorage", %{venue_ids: venue_ids})
    |> noreply()
  end

  @impl true
  def handle_event("clear-venue-filtering", _params, socket) do
    venue_ids = []

    paged_events =
      MusicListings.list_events(page: socket.assigns[:current_page], venue_ids: venue_ids)

    socket
    |> update_socket_assigns(paged_events, venue_ids)
    |> push_event("clearVenueFilterIdsFromLocalStorage", %{})
    |> noreply()
  end

  @impl true
  def handle_event(
        "delete-event",
        %{"id" => event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    MusicListings.delete_event(current_user, event_id)

    paged_events =
      MusicListings.list_events(
        page: socket.assigns[:current_page],
        venue_ids: socket.assigns[:venue_ids]
      )

    socket
    |> update_socket_assigns(paged_events)
    |> noreply()
  end

  defp update_socket_assigns(socket, paged_events) do
    socket
    |> assign(:events, paged_events.events)
    |> assign(:current_page, paged_events.current_page)
    |> assign(:total_pages, paged_events.total_pages)
  end

  defp update_socket_assigns(socket, paged_events, venue_ids) do
    socket
    |> update_socket_assigns(paged_events)
    |> assign(:venue_ids, venue_ids)
  end

  defparams :index do
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex justify-between mb-8 sm:mb-4 -mt-2"
      data-venue-filter-restore="true"
      data-storage-key="venue_ids"
    >
      <.venue_filter for={@venue_filtering_form} venues={@venues} venue_ids={@venue_ids} />
      <.button_link label="Submit an event" url={~p"/events/new"} icon_name="hero-arrow-right" />
    </div>

    <.venue_filter_status venue_ids={@venue_ids} />

    <%= if @loading do %>
      <.loading_indicator />
    <% end %>

    <.events_list events={@events} current_user={@current_user} />

    <div class="mt-6 pt-6 border-t border-zinc-700">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    </div>
    """
  end
end
