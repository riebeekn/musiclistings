defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :events, MusicListings.list_events())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= for {date, events} <- @events do %>
      <div>
        <h2 class="text-3xl text-blue-600 font-bold">
          <%= MusicListingsUtilities.DateHelpers.format_date(date) %>
        </h2>
        <%= for event <- events do %>
          <div>
            <%= event.title %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end
end
