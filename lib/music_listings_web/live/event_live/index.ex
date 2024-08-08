defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = parse_page_param(params)
    paged_events = MusicListings.list_events(page: page)

    socket =
      socket
      |> assign(:events, paged_events.events)
      |> assign(:current_page, paged_events.current_page)
      |> assign(:total_pages, paged_events.total_pages)

    {:noreply, socket}
  end

  @default_page "1"
  defp parse_page_param(params) do
    params
    |> Map.get("page", @default_page)
    |> Integer.parse()
    |> case do
      :error -> String.to_integer(@default_page)
      {page, _remainder} -> max(page, 1)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :for={{date, events} <- @events} class="mb-8 divide-y divide-solid divide-blue-600">
      <.events_date_header date={date} />
      <ul role="list" class="mt-2 mb-4">
        <%= for event <- events do %>
          <.event_card event={event} />
        <% end %>
      </ul>
    </div>

    <%= if @current_page > 1 do %>
      <.button_patch_link label="Prev page" url={~p"/events?#{[page: @current_page - 1]}"} />
    <% end %>
    <%= if @current_page < @total_pages do %>
      <.button_patch_link label="Next page" url={~p"/events?#{[page: @current_page + 1]}"} />
    <% end %>
    """
  end
end
