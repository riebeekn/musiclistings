defmodule MusicListingsWeb.VenueLive.Index do
  use MusicListingsWeb, :live_view

  import MusicListingsWeb.VenueComponents

  alias MusicListings.Accounts.User
  alias MusicListingsWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign_venues()
    |> assign(
      page_title: "Venues",
      crawling?: false,
      crawling_venue_id: nil,
      meta_description:
        "Browse every Toronto music venue we track — from small clubs to concert halls. Find upcoming shows, addresses, and venue details.",
      canonical_url: SEO.canonical_url("/venues")
    )
    |> ok()
  end

  @impl true
  def handle_event("crawl-all-venues", _params, socket) do
    if socket.assigns.crawling? do
      noreply(socket)
    else
      current_user = socket.assigns.current_user

      socket
      |> assign(:crawling?, true)
      |> start_async(:crawl, fn -> MusicListings.crawl_all_venues(current_user) end)
      |> noreply()
    end
  end

  @impl true
  def handle_event("crawl-venue", %{"id" => venue_id}, socket) do
    if socket.assigns.crawling? do
      noreply(socket)
    else
      current_user = socket.assigns.current_user

      socket
      |> assign(:crawling?, true)
      |> assign(:crawling_venue_id, venue_id)
      |> start_async(:crawl, fn -> MusicListings.crawl_venue(current_user, venue_id) end)
      |> noreply()
    end
  end

  @impl true
  def handle_event(
        "toggle-pull-events",
        %{"id" => venue_id, "pull-events" => pull_events},
        socket
      ) do
    socket.assigns.current_user
    |> MusicListings.set_pull_events(venue_id, pull_events == "true")
    |> case do
      {:ok, venue} ->
        socket
        |> assign_venues()
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
    socket
    |> assign(:crawling?, false)
    |> assign(:crawling_venue_id, nil)
    |> assign_venues()
    |> crawl_flash(result)
    |> noreply()
  end

  def handle_async(:crawl, {:exit, _reason}, socket) do
    socket
    |> assign(:crawling?, false)
    |> assign(:crawling_venue_id, nil)
    |> put_flash(:error, "Crawl failed.")
    |> noreply()
  end

  # Everyone sees the venues being crawled; an admin also sees the rest, to turn on
  defp assign_venues(socket) do
    {venues, inactive_venues} =
      if admin?(socket.assigns.current_user) do
        [restrict_to_pulled_venues?: false]
        |> MusicListings.list_venues()
        |> Enum.split_with(& &1.pull_events?)
      else
        {MusicListings.list_venues(), []}
      end

    assign(socket,
      venues: venues,
      venue_count: Enum.count(venues),
      inactive_venues: inactive_venues
    )
  end

  defp admin?(%User{role: :admin}), do: true
  defp admin?(_user_or_nil), do: false

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

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header header="Venues" description={"Tracking events from #{@venue_count} venues."} />
    <.when_admin current_user={@current_user}>
      <div class="mt-4 flex flex-wrap gap-3">
        <.button_link url={~p"/venues/new"} label="New Venue" />
        <.button
          phx-click="crawl-all-venues"
          disabled={@crawling?}
          data-confirm="Crawl all venues? This hits every venue site."
        >
          <%= if @crawling? do %>
            <.icon name="hero-arrow-path" class="size-4 animate-spin" /> Crawling…
          <% else %>
            <.icon name="hero-arrow-path" class="size-4" /> Crawl all venues
          <% end %>
        </.button>
      </div>
    </.when_admin>
    <.venue_summary
      venues={@venues}
      current_user={@current_user}
      crawling?={@crawling?}
      crawling_venue_id={@crawling_venue_id}
    />
    <.when_admin current_user={@current_user}>
      <section :if={@inactive_venues != []} id="inactive-venues" class="mt-16">
        <h2 class="headline text-3xl text-paper sm:text-4xl">Not pulling events</h2>
        <p class="mt-3 max-w-xl text-sm leading-relaxed text-paper-dim">
          {Enum.count(@inactive_venues)} venues aren't being crawled. Only admins see this list.
        </p>
        <.venue_summary
          venues={@inactive_venues}
          current_user={@current_user}
          crawling?={@crawling?}
          crawling_venue_id={@crawling_venue_id}
        />
      </section>
    </.when_admin>
    """
  end

  attr :venues, :list, required: true
  attr :current_user, :any, default: nil
  attr :crawling?, :boolean, default: false
  attr :crawling_venue_id, :any, default: nil

  defp venue_summary(assigns) do
    ~H"""
    <div class="mt-8 grid grid-cols-1 border-t border-hairline sm:grid-cols-2">
      <%= for venue <- @venues do %>
        <div class="group relative border-b border-hairline transition-colors hover:bg-ink-2/60 sm:[&:nth-child(odd)]:border-r">
          <a
            href={~p"/events/venue/#{venue.id}"}
            id={"venue-#{venue.id}"}
            class="flex items-center justify-between gap-4 py-5 sm:px-5"
          >
            <div class="min-w-0 flex-1">
              <h3 class="font-display text-2xl font-bold leading-none text-paper transition-colors group-hover:text-spotlight">
                {venue.name}
              </h3>
              <p class="kicker mt-1.5">{venue.street}</p>
            </div>
            <span class="shrink-0 bg-spotlight/10 text-spotlight px-3 py-1 font-mono text-xs tabular-nums uppercase tracking-wider">
              {venue.upcoming_event_count} Upcoming Events
            </span>
          </a>
          <.when_admin current_user={@current_user}>
            <div class="flex flex-wrap gap-3 pb-4 sm:px-5">
              <.button
                phx-click="crawl-venue"
                phx-value-id={venue.id}
                disabled={@crawling?}
              >
                <.icon
                  name="hero-arrow-path"
                  class={"size-4 #{if to_string(venue.id) == @crawling_venue_id, do: "animate-spin"}"}
                /> Crawl
              </.button>
              <.pull_events_toggle venue={venue} />
            </div>
          </.when_admin>
        </div>
      <% end %>
    </div>
    """
  end
end
