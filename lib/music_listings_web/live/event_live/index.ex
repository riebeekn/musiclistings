defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    venue_ids = get_venue_ids_in_local_storage(socket)

    selected_date =
      get_selected_date_in_local_storage(socket) || Date.to_iso8601(Date.utc_today())

    venues = MusicListings.list_venues(restrict_to_pulled_venues?: false)
    Sentry.capture_message("Just a test!!!")

    socket
    |> assign(:venues, venues)
    |> assign(:venue_ids, venue_ids)
    |> assign(:selected_date, selected_date)
    |> assign(:venue_filtering_form, to_form(%{}))
    |> assign(:date_filtering_form, to_form(%{}))
    |> ok()
  end

  defp get_venue_ids_in_local_storage(socket) do
    socket
    |> get_connect_params()
    |> case do
      %{"venue_ids" => venue_ids} when is_binary(venue_ids) ->
        venue_ids
        |> String.split(",")
        |> filter_venue_ids()

      _default ->
        []
    end
  end

  defp filter_venue_ids(venue_ids) do
    Enum.filter(venue_ids, fn venue_id ->
      case Integer.parse(venue_id) do
        {_valid_integer, ""} -> true
        _non_integer -> false
      end
    end)
  end

  defp get_selected_date_in_local_storage(socket) do
    today = Date.utc_today()

    with %{"selected_date" => selected_date} when is_binary(selected_date) <-
           get_connect_params(socket),
         {:ok, date} <- Date.from_iso8601(selected_date),
         comparison when comparison in [:gt, :eq] <- Date.compare(date, today) do
      selected_date
    else
      _invalid_or_past_date -> nil
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      venue_ids = socket.assigns[:venue_ids] || []
      selected_date = socket.assigns[:selected_date]

      case validate(:index, params) do
        {:ok, normalized_params} ->
          from_date = parse_selected_date(selected_date)

          paged_events =
            MusicListings.list_events(
              page: normalized_params[:page],
              venue_ids: venue_ids,
              from_date: from_date
            )

          socket
          |> update_socket_assigns(paged_events, venue_ids)
          |> assign(:loading, false)
          |> noreply()

        _error ->
          socket
          |> push_navigate(to: ~p"/events")
          |> noreply()
      end
    else
      socket
      |> assign(:events, [])
      |> assign(:current_page, 1)
      |> assign(:total_pages, 0)
      |> assign(:loading, true)
      |> noreply()
    end
  end

  @impl true
  def handle_event("venue-filter-selected", venues_filter, socket) do
    venue_ids =
      venues_filter
      |> Map.keys()
      |> Enum.filter(fn key ->
        case Integer.parse(key) do
          :error -> false
          _is_venue_id -> true
        end
      end)

    from_date = parse_selected_date(socket.assigns[:selected_date])

    paged_events =
      MusicListings.list_events(
        page: socket.assigns[:current_page],
        venue_ids: venue_ids,
        from_date: from_date
      )

    socket
    |> update_socket_assigns(paged_events, venue_ids)
    |> push_event("saveVenueFilterIdsToLocalStorage", %{venue_ids: venue_ids})
    |> noreply()
  end

  @impl true
  def handle_event("clear-venue-filtering", _params, socket) do
    venue_ids = []

    from_date = parse_selected_date(socket.assigns[:selected_date])

    paged_events =
      MusicListings.list_events(
        page: socket.assigns[:current_page],
        venue_ids: venue_ids,
        from_date: from_date
      )

    socket
    |> update_socket_assigns(paged_events, venue_ids)
    |> push_event("clearVenueFilterIdsFromLocalStorage", %{})
    |> noreply()
  end

  @impl true
  def handle_event("date-filter-changed", %{"date" => date}, socket) do
    selected_date = parse_selected_date(date)

    paged_events =
      MusicListings.list_events(
        page: 1,
        venue_ids: socket.assigns[:venue_ids],
        from_date: selected_date
      )

    selected_date_string = if selected_date, do: Date.to_iso8601(selected_date), else: ""

    socket
    |> update_socket_assigns(paged_events)
    |> assign(:selected_date, selected_date_string)
    |> assign(:current_page, 1)
    |> push_event("saveDateFilterToLocalStorage", %{selected_date: selected_date_string})
    |> noreply()
  end

  @impl true
  def handle_event("clear-date-filter", _params, socket) do
    today = Date.to_iso8601(Date.utc_today())
    selected_date = parse_selected_date(today)

    paged_events =
      MusicListings.list_events(
        page: 1,
        venue_ids: socket.assigns[:venue_ids],
        from_date: selected_date
      )

    socket
    |> update_socket_assigns(paged_events)
    |> assign(:selected_date, today)
    |> assign(:current_page, 1)
    |> push_event("saveDateFilterToLocalStorage", %{selected_date: today})
    |> noreply()
  end

  @impl true
  def handle_event(
        "delete-event",
        %{"id" => event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    MusicListings.delete_event(current_user, event_id)

    paged_events =
      MusicListings.list_events(
        page: socket.assigns[:current_page],
        venue_ids: socket.assigns[:venue_ids]
      )

    socket
    |> update_socket_assigns(paged_events)
    |> noreply()
  end

  defp update_socket_assigns(socket, paged_events) do
    socket
    |> assign(:events, paged_events.events)
    |> assign(:current_page, paged_events.current_page)
    |> assign(:total_pages, paged_events.total_pages)
  end

  defp update_socket_assigns(socket, paged_events, venue_ids) do
    socket
    |> update_socket_assigns(paged_events)
    |> assign(:venue_ids, venue_ids)
  end

  defp parse_selected_date(nil), do: nil

  defp parse_selected_date(""), do: nil

  defp parse_selected_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _error -> nil
    end
  end

  defparams :index do
    optional(:page, :integer, min: 1, default: 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex flex-wrap gap-2 justify-between mb-8 sm:mb-4 -mt-2"
      data-venue-filter-restore="true"
      data-storage-key="venue_ids"
      data-date-filter-restore="true"
      data-date-storage-key="selected_date"
    >
      <div class="flex flex-wrap gap-2">
        <.venue_filter for={@venue_filtering_form} venues={@venues} venue_ids={@venue_ids} />
        <.date_filter for={@date_filtering_form} selected_date={@selected_date} />
      </div>
      <.button_link label="Submit an event" url={~p"/events/new"} icon_name="hero-arrow-right" />
    </div>

    <.venue_filter_status venue_ids={@venue_ids} />
    <.date_filter_status selected_date={@selected_date} />

    <%= if @loading do %>
      <.loading_indicator />
    <% end %>

    <.events_list events={@events} current_user={@current_user} />

    <div class="mt-6 pt-6 border-t border-zinc-700">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    </div>
    """
  end
end
