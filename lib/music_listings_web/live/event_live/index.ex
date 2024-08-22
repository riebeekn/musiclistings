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
    <div :for={{date, events} <- @events} class="mb-8">
      <.events_date_header date={date} />
      <div class="mt-2">
        <.events_table events={events} />
      </div>
    </div>

    <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    """
  end
end
