defmodule MusicListingsWeb.SubmittedEventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListingsUtilities.DateHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    if connected?(socket) do
      case validate(:index, params) do
        {:ok, normalized_params} ->
          paged_events =
            MusicListings.list_submitted_events(current_user, page: normalized_params[:page])

          socket
          |> update_socket_assigns(paged_events)
          |> assign(:loading, false)
          |> noreply()

        _error ->
          socket
          |> push_navigate(to: ~p"/events")
          |> noreply()
      end
    else
      socket
      |> assign(:submitted_events, [])
      |> assign(:current_page, 1)
      |> assign(:total_pages, 0)
      |> assign(:selected_ids, MapSet.new())
      |> assign(:loading, true)
      |> noreply()
    end
  end

  @impl true
  def handle_event(
        "approve-submitted-event",
        %{"id" => submitted_event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    current_user
    |> MusicListings.approve_submitted_event(submitted_event_id)
    |> case do
      {:ok, _event} ->
        paged_events =
          MusicListings.list_submitted_events(current_user, page: socket.assigns[:page])

        socket
        |> update_socket_assigns(paged_events)
        |> noreply()

      {:error, :venue_not_found} ->
        socket
        |> put_flash(:error, "Venue not found")
        |> noreply()

      {:error, :submitted_event_not_found} ->
        socket
        |> put_flash(:error, "Submitted event not found")
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Auth error")
        |> noreply()
    end
  end

  def handle_event("toggle-select", %{"id" => submitted_event_id}, socket) do
    id = String.to_integer(submitted_event_id)
    selected_ids = socket.assigns.selected_ids

    updated_selected_ids =
      if MapSet.member?(selected_ids, id) do
        MapSet.delete(selected_ids, id)
      else
        MapSet.put(selected_ids, id)
      end

    socket
    |> assign(:selected_ids, updated_selected_ids)
    |> noreply()
  end

  def handle_event("toggle-select-all", _params, socket) do
    all_ids = MapSet.new(socket.assigns.submitted_events, & &1.id)

    selected_ids =
      if MapSet.equal?(socket.assigns.selected_ids, all_ids) do
        MapSet.new()
      else
        all_ids
      end

    socket
    |> assign(:selected_ids, selected_ids)
    |> noreply()
  end

  def handle_event(
        "delete-selected",
        _params,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    submitted_event_ids = MapSet.to_list(socket.assigns.selected_ids)

    current_user
    |> MusicListings.delete_submitted_events(submitted_event_ids)
    |> case do
      {:ok, count} ->
        paged_events =
          MusicListings.list_submitted_events(current_user, page: socket.assigns.current_page)

        socket
        |> update_socket_assigns(paged_events)
        |> put_flash(:info, "Deleted #{count} submitted #{ngettext("event", "events", count)}")
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Auth error")
        |> noreply()
    end
  end

  defp update_socket_assigns(socket, paged_events) do
    socket
    |> assign(:submitted_events, paged_events.events)
    |> assign(:current_page, paged_events.current_page)
    |> assign(:total_pages, paged_events.total_pages)
    |> assign(:selected_ids, MapSet.new())
  end

  defparams :index do
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @loading do %>
      <.loading_indicator />
    <% end %>

    <.page_header header="Submitted Events" />

    <div class="mt-4">
      <.submitted_events submitted_events={@submitted_events} selected_ids={@selected_ids} />
    </div>

    <div class="mt-6 pt-6 border-t border-hairline">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/submitted_events"} />
    </div>
    """
  end

  attr :submitted_events, :list, required: true
  attr :selected_ids, :any, required: true

  defp submitted_events(assigns) do
    all_selected =
      assigns.submitted_events != [] and
        Enum.all?(assigns.submitted_events, &MapSet.member?(assigns.selected_ids, &1.id))

    assigns = assign(assigns, :all_selected, all_selected)

    ~H"""
    <div>
      <div class="flex items-center justify-between gap-4 border-b border-hairline pb-3">
        <label class="inline-flex items-center gap-2 text-sm text-paper-dim cursor-pointer">
          <.select_checkbox
            checked={@all_selected}
            phx-click="toggle-select-all"
            aria-label="Select all"
          /> Select all
        </label>
        <button
          phx-click="delete-selected"
          data-confirm="Are you sure?"
          disabled={MapSet.size(@selected_ids) == 0}
          class={[
            pill_class(),
            "bg-ember/10 text-ember ring-1 ring-inset ring-ember/30 hover:bg-ember hover:text-ink disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-ember/10 disabled:hover:text-ember"
          ]}
        >
          Delete selected ({MapSet.size(@selected_ids)})
        </button>
      </div>

      <p :if={@submitted_events == []} class="py-10 text-center text-sm text-paper-dim">
        No submitted events.
      </p>

      <ul role="list" class="divide-y divide-hairline">
        <li
          :for={submitted_event <- @submitted_events}
          id={"event-#{submitted_event.id}"}
          class="py-5"
        >
          <div class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-3 sm:grid-cols-[auto_1fr_auto] sm:items-start sm:gap-x-6">
            <div class="pt-1">
              <.select_checkbox
                checked={MapSet.member?(@selected_ids, submitted_event.id)}
                phx-click="toggle-select"
                phx-value-id={submitted_event.id}
                aria-label="Select submitted event"
              />
            </div>

            <div class="min-w-0">
              <div class="font-display text-xl font-bold leading-tight text-paper">
                {submitted_event.title}
              </div>
              <a
                :if={submitted_event.url}
                href={submitted_event.url}
                target="_blank"
                rel="noopener"
                class="mt-0.5 block text-sm text-spotlight hover:text-spotlight-deep break-all"
              >
                {submitted_event.url}
              </a>
              <div class="mt-2 flex flex-wrap items-center gap-x-2 gap-y-1 text-sm text-paper-dim">
                <span class="inline-flex items-center gap-1">
                  <.icon name="hero-map-pin" class="size-3.5" />
                  {submitted_event.venue}
                </span>
                <span aria-hidden="true">·</span>
                <span>{DateHelpers.format_date(submitted_event.date)}</span>
                <span :if={submitted_event.time} aria-hidden="true">·</span>
                <span :if={submitted_event.time}>{submitted_event.time}</span>
                <span :if={submitted_event.price} aria-hidden="true">·</span>
                <span :if={submitted_event.price}>{submitted_event.price}</span>
              </div>
            </div>

            <div class="col-span-2 sm:col-span-1">
              <.submitted_event_actions submitted_event={submitted_event} />
            </div>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  attr :checked, :boolean, required: true
  attr :rest, :global

  defp select_checkbox(assigns) do
    ~H"""
    <input
      type="checkbox"
      checked={@checked}
      class="h-4 w-4 rounded border-paper-dim bg-ink-2 text-spotlight focus:ring-spotlight cursor-pointer"
      {@rest}
    />
    """
  end

  defp pill_class do
    "inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition-colors rounded-full py-1 px-3"
  end

  defp submitted_event_actions(assigns) do
    ~H"""
    <div class="flex items-center gap-2 sm:justify-end">
      <span :if={@submitted_event.approved?} class="text-sm font-medium text-amber-400">
        Approved
      </span>
      <.link
        :if={!@submitted_event.approved?}
        navigate={~p"/submitted_events/#{@submitted_event.id}/edit"}
        class={[
          pill_class(),
          "text-paper-dim ring-1 ring-inset ring-hairline hover:text-paper hover:ring-paper-dim"
        ]}
      >
        Edit
      </.link>
      <button
        :if={!@submitted_event.approved?}
        phx-click="approve-submitted-event"
        phx-value-id={@submitted_event.id}
        data-confirm="Are you sure?"
        class={[
          pill_class(),
          "bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30 hover:bg-spotlight hover:text-ink"
        ]}
      >
        Approve
      </button>
    </div>
    """
  end
end
