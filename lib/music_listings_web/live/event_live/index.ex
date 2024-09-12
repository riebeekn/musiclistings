defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case validate(:index, params) do
      {:ok, normalized_params} ->
        paged_events = MusicListings.list_events(page: normalized_params[:page])

        socket =
          socket
          |> assign(:events, paged_events.events)
          |> assign(:current_page, paged_events.current_page)
          |> assign(:total_pages, paged_events.total_pages)

        {:noreply, socket}

      _error ->
        {:noreply, push_navigate(socket, to: ~p"/events")}
    end
  end

  defparams :index do
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.events_list events={@events} />

    <div class="mt-6 pt-6 border-t border-zinc-700">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    </div>
    """
  end
end
