defmodule MusicListingsWeb.VenueLive.Index do
  use MusicListingsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    venues = MusicListings.list_venues()

    {:ok, assign(socket, venues: venues)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header header="Venues" description="Tracking events for the following venues." />
    <.venue_summary venues={@venues} />
    """
  end
end
