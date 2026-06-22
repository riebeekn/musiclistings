defmodule MusicListingsWeb.VenueEventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListingsWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:crawling?, false)
    |> ok()
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

  @impl true
  def handle_event("crawl-venue", _params, socket) do
    if socket.assigns.crawling? do
      noreply(socket)
    else
      current_user = socket.assigns.current_user
      venue_id = socket.assigns.venue.id

      socket
      |> assign(:crawling?, true)
      |> start_async(:crawl, fn -> MusicListings.crawl_venue(current_user, venue_id) end)
      |> noreply()
    end
  end

  @impl true
  def handle_async(:crawl, {:ok, result}, socket) do
    paged_events =
      MusicListings.list_events(
        page: socket.assigns[:current_page],
        venue_ids: [socket.assigns[:venue].id]
      )

    socket
    |> assign(:crawling?, false)
    |> assign(:events, paged_events.events)
    |> crawl_flash(result)
    |> noreply()
  end

  def handle_async(:crawl, {:exit, _reason}, socket) do
    socket
    |> assign(:crawling?, false)
    |> put_flash(:error, "Crawl failed.")
    |> noreply()
  end

  defp crawl_flash(socket, {:ok, summary}) do
    put_flash(
      socket,
      :info,
      "Crawl complete: #{summary.new} new, #{summary.updated} updated, #{summary.errors} error(s)"
    )
  end

  defp crawl_flash(socket, {:error, :not_allowed}), do: put_flash(socket, :error, "Not allowed.")
  defp crawl_flash(socket, _result), do: put_flash(socket, :error, "Crawl failed.")

  defparams :index do
    required(:venue_id, :integer, min: 1)
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mb-10">
      <.venue_card venue={@venue} />
      <.when_admin current_user={@current_user}>
        <div class="mt-4">
          <.button phx-click="crawl-venue" disabled={@crawling?}>
            <.icon name="hero-arrow-path" class={"size-4 #{if @crawling?, do: "animate-spin"}"} />
            {if @crawling?, do: "Crawling…", else: "Crawl this venue"}
          </.button>
        </div>
      </.when_admin>
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
