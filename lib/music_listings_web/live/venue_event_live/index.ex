defmodule MusicListingsWeb.VenueEventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  import MusicListingsWeb.EventComponents
  import MusicListingsWeb.VenueComponents

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
  def handle_event("clear-venue-events", _params, socket) do
    venue = socket.assigns.venue

    socket.assigns.current_user
    |> MusicListings.clear_venue_events(venue.id)
    |> case do
      {:ok, count} ->
        socket
        |> assign(:events, [])
        |> assign(:current_page, 1)
        |> assign(:total_pages, 1)
        |> put_flash(:info, "Cleared #{count} event(s) for #{venue.name}.")
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Not allowed.")
        |> noreply()
    end
  end

  @impl true
  def handle_event("toggle-pull-events", %{"pull-events" => pull_events}, socket) do
    socket.assigns.current_user
    |> MusicListings.set_pull_events(socket.assigns.venue.id, pull_events == "true")
    |> case do
      {:ok, venue} ->
        socket
        |> assign(:venue, venue)
        |> put_flash(:info, pull_events_flash(venue))
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Not allowed.")
        |> noreply()

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Couldn't update the venue.")
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

  defp pull_events_flash(%{pull_events?: true, name: name}), do: "Now pulling events for #{name}."
  defp pull_events_flash(%{name: name}), do: "Stopped pulling events for #{name}."

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
        <div class="mt-4 flex flex-wrap items-center gap-3">
          <.button phx-click="crawl-venue" disabled={@crawling?}>
            <.icon name="hero-arrow-path" class={"size-4 #{if @crawling?, do: "animate-spin"}"} />
            {if @crawling?, do: "Crawling…", else: "Crawl this venue"}
          </.button>
          <.button
            phx-click="clear-venue-events"
            disabled={@crawling?}
            data-confirm={"Permanently delete ALL events for #{@venue.name}, including past ones? This can't be undone."}
          >
            <.icon name="hero-trash" class="size-4" /> Clear all events
          </.button>
          <.pull_events_toggle venue={@venue} />
        </div>
      </.when_admin>
    </div>

    <div class="mb-2 flex items-end gap-5">
      <h2 class="headline text-3xl whitespace-nowrap text-paper sm:text-4xl">Upcoming Events</h2>
      <div class="mb-2 h-px flex-1 bg-hairline"></div>
    </div>

    <.venue_events_list
      events={@events}
      current_user={@current_user}
    />

    <div class="my-8">
      <.pager
        current_page={@current_page}
        total_pages={@total_pages}
        path={~p"/events/venue/#{@venue.id}"}
      />
    </div>
    """
  end

  attr :venue, :map, required: true

  defp venue_card(assigns) do
    ~H"""
    <div class="border-b border-hairline pb-8">
      <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
        <div class="flex-1">
          <p class="kicker flex items-center gap-2">
            <span class="inline-block h-2 w-8 bg-spotlight"></span> Venue
          </p>
          <h1 class="headline mt-3 text-5xl text-paper sm:text-6xl lg:text-7xl">
            {@venue.name}
          </h1>
          <div class="mt-4 space-y-0.5 font-mono text-sm text-paper-dim">
            <p>{@venue.street}</p>
            <p>{"#{@venue.city} #{@venue.province} · #{@venue.country} #{@venue.postal_code}"}</p>
          </div>
          <a
            href={@venue.website}
            target="_blank"
            rel="noopener"
            class="mt-4 inline-flex items-center gap-1.5 font-mono text-xs uppercase tracking-wider text-spotlight transition-colors hover:text-spotlight-deep"
          >
            <.icon
              name="hero-arrow-top-right-on-square"
              class="size-4"
            /> Visit website
          </a>
        </div>

        <div class="h-48 w-full overflow-hidden border border-hairline grayscale transition-all duration-300 hover:grayscale-0 lg:w-96">
          <iframe
            id={"venue-map-#{@venue.id}"}
            class="w-full h-full"
            src={@venue.google_map_url}
            frameborder="0"
            style="border:0;"
            allowfullscreen=""
            aria-hidden="false"
            tabindex="0"
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
            sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"
            phx-update="ignore"
          ></iframe>
        </div>
      </div>
    </div>
    """
  end
end
