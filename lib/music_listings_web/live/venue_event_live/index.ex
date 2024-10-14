defmodule MusicListingsWeb.VenueEventLive.Index do
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
        venue = MusicListings.get_venue!(normalized_params.venue_id)

        paged_events =
          MusicListings.list_events(
            page: normalized_params[:page],
            venue_ids: [normalized_params.venue_id],
            order_by: [:date, :time]
          )

        socket =
          socket
          |> assign(
            :events,
            paged_events.events |> Enum.flat_map(fn {_date, events} -> events end)
          )
          |> assign(:venue, venue)
          |> assign(:current_page, paged_events.current_page)
          |> assign(:total_pages, paged_events.total_pages)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, push_navigate(socket, to: ~p"/events")}
    end
  end

  defparams :index do
    required(:venue_id, :integer, min: 1)
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mb-6 sm:mb-12">
      <.venue_card venue={@venue} />
    </div>

    <div class="mb-2">
      <.page_header header="Upcoming Events" />
    </div>

    <.venue_events_list events={@events} />

    <div class="my-8">
      <.pager
        current_page={@current_page}
        total_pages={@total_pages}
        path={~p"/events/venue/#{@venue.id}"}
      />
    </div>
    """
  end
end
