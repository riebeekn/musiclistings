defmodule MusicListingsWeb.VenueLive.Index do
  use MusicListingsWeb, :live_view

  alias MusicListingsWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    venues = MusicListings.list_venues()

    socket
    |> assign(
      page_title: "Venues",
      venues: venues,
      venue_count: Enum.count(venues),
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
  def handle_async(:crawl, {:ok, result}, socket) do
    venues = MusicListings.list_venues()

    socket
    |> assign(:crawling?, false)
    |> assign(:crawling_venue_id, nil)
    |> assign(:venues, venues)
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
    """
  end
end
