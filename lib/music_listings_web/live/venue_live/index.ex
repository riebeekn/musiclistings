defmodule MusicListingsWeb.VenueLive.Index do
  use MusicListingsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    venues = MusicListings.list_venues()

    socket
    |> assign(page_title: "Venues", venues: venues, venue_count: Enum.count(venues))
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header header="Venues" description={"Tracking events from #{@venue_count} venues."} />
    <%= if @current_user do %>
      <div class="mt-4">
        <.button_link url={~p"/venues/new"} label="New Venue" />
      </div>
    <% end %>
    <.venue_summary venues={@venues} />
    """
  end
end
