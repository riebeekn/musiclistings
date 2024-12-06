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
    <.venue_summary venues={@venues} />
    """
  end
end
