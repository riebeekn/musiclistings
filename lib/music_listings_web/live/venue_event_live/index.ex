defmodule MusicListingsWeb.VenueEventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    ok(socket)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case validate(:index, params) do
      {:ok, normalized_params} ->
        venue = MusicListings.get_venue!(normalized_params.venue_id)

        paged_events =
          MusicListings.list_events(
            page: normalized_params[:page],
            venue_ids: [normalized_params.venue_id]
          )

        socket
        |> assign(
          :events,
          paged_events.events |> Enum.flat_map(fn {_date, events} -> events end)
        )
        |> assign(:page_title, venue.name)
        |> assign(:venue, venue)
        |> assign(:current_page, paged_events.current_page)
        |> assign(:total_pages, paged_events.total_pages)
        |> noreply()

      {:error, _changeset} ->
        socket
        |> push_navigate(to: ~p"/events")
        |> noreply()
    end
  end

  @impl true
  def handle_event(
        "delete-event",
        %{"id" => event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    current_user
    |> MusicListings.delete_event(event_id)
    |> case do
      {:ok, _deleted_event} ->
        paged_events =
          MusicListings.list_events(
            page: socket.assigns[:current_page],
            venue_ids: [socket.assigns[:venue].id]
          )

        socket
        |> assign(
          :events,
          paged_events.events |> Enum.flat_map(fn {_date, events} -> events end)
        )
        |> noreply()

      _no_change ->
        noreply(socket)
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

    <.venue_events_list events={@events} current_user={@current_user} />

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
