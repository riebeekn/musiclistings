defmodule MusicListingsWeb.VenueEventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListingsWeb.SEO

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

        meta_description =
          "Upcoming live music events at #{venue.name} in Toronto. View showtimes, prices, and ticket links — updated daily."

        json_ld = [
          SEO.venue_json_ld(venue),
          paged_events.events
          |> SEO.grouped_events_to_list_items()
          |> SEO.event_list_json_ld()
        ]

        socket
        |> assign(:events, paged_events.events)
        |> assign(:page_title, venue.name)
        |> assign(:venue, venue)
        |> assign(:current_page, paged_events.current_page)
        |> assign(:total_pages, paged_events.total_pages)
        |> assign(:meta_description, meta_description)
        |> assign(:canonical_url, SEO.canonical_url("/events/venue/#{venue.id}"))
        |> assign(:json_ld, json_ld)
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
        |> assign(:events, paged_events.events)
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
    <div class="mb-10">
      <.venue_card venue={@venue} />
    </div>

    <div class="mb-2 flex items-end gap-5">
      <h2 class="headline text-3xl whitespace-nowrap text-paper sm:text-4xl">Upcoming Events</h2>
      <div class="mb-2 h-px flex-1 bg-hairline"></div>
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
