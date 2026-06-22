defmodule MusicListingsWeb.SubmittedEventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    if connected?(socket) do
      case validate(:index, params) do
        {:ok, normalized_params} ->
          paged_events =
            MusicListings.list_submitted_events(current_user, page: normalized_params[:page])

          socket
          |> update_socket_assigns(paged_events)
          |> assign(:loading, false)
          |> noreply()

        _error ->
          socket
          |> push_navigate(to: ~p"/events")
          |> noreply()
      end
    else
      socket
      |> assign(:submitted_events, [])
      |> assign(:current_page, 1)
      |> assign(:total_pages, 0)
      |> assign(:selected_ids, MapSet.new())
      |> assign(:loading, true)
      |> noreply()
    end
  end

  @impl true
  def handle_event(
        "approve-submitted-event",
        %{"id" => submitted_event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    current_user
    |> MusicListings.approve_submitted_event(submitted_event_id)
    |> case do
      {:ok, _event} ->
        paged_events =
          MusicListings.list_submitted_events(current_user, page: socket.assigns[:page])

        socket
        |> update_socket_assigns(paged_events)
        |> noreply()

      {:error, :venue_not_found} ->
        socket
        |> put_flash(:error, "Venue not found")
        |> noreply()

      {:error, :submitted_event_not_found} ->
        socket
        |> put_flash(:error, "Submitted event not found")
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Auth error")
        |> noreply()
    end
  end

  def handle_event("toggle-select", %{"id" => submitted_event_id}, socket) do
    id = String.to_integer(submitted_event_id)
    selected_ids = socket.assigns.selected_ids

    updated_selected_ids =
      if MapSet.member?(selected_ids, id) do
        MapSet.delete(selected_ids, id)
      else
        MapSet.put(selected_ids, id)
      end

    socket
    |> assign(:selected_ids, updated_selected_ids)
    |> noreply()
  end

  def handle_event("toggle-select-all", _params, socket) do
    all_ids = MapSet.new(socket.assigns.submitted_events, & &1.id)

    selected_ids =
      if MapSet.equal?(socket.assigns.selected_ids, all_ids) do
        MapSet.new()
      else
        all_ids
      end

    socket
    |> assign(:selected_ids, selected_ids)
    |> noreply()
  end

  def handle_event(
        "delete-selected",
        _params,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    submitted_event_ids = MapSet.to_list(socket.assigns.selected_ids)

    current_user
    |> MusicListings.delete_submitted_events(submitted_event_ids)
    |> case do
      {:ok, count} ->
        paged_events =
          MusicListings.list_submitted_events(current_user, page: socket.assigns.current_page)

        socket
        |> update_socket_assigns(paged_events)
        |> put_flash(:info, "Deleted #{count} submitted #{ngettext("event", "events", count)}")
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Auth error")
        |> noreply()
    end
  end

  defp update_socket_assigns(socket, paged_events) do
    socket
    |> assign(:submitted_events, paged_events.events)
    |> assign(:current_page, paged_events.current_page)
    |> assign(:total_pages, paged_events.total_pages)
    |> assign(:selected_ids, MapSet.new())
  end

  defparams :index do
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @loading do %>
      <.loading_indicator />
    <% end %>

    <.page_header header="Submitted Events" />

    <div class="mt-4">
      <.submitted_events submitted_events={@submitted_events} selected_ids={@selected_ids} />
    </div>

    <div class="mt-6 pt-6 border-t border-hairline">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/submitted_events"} />
    </div>
    """
  end
end
