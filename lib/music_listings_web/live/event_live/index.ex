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
      <div class="mb-8 divide-y divide-solid divide-blue-600">
        <.events_date_header date={date} />
        <ul role="list" class="mt-2 mb-4">
          <%= for event <- events do %>
            <.event_card event={event} />
          <% end %>
        </ul>
      </div>
    <% end %>
    """
  end
end
