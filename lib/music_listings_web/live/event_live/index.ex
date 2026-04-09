defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListingsUtilities.DateHelpers

  @impl true
  def mount(_params, _session, socket) do
    venue_ids = get_venue_ids_in_local_storage(socket)

    selected_date =
      get_selected_date_in_local_storage(socket) ||
        Date.to_iso8601(DateHelpers.effective_today_eastern())

    sort_by = get_sort_by_in_local_storage(socket)
    venues = MusicListings.list_venues(restrict_to_pulled_venues?: false)

    socket
    |> assign(:venues, venues)
    |> assign(:venue_ids, venue_ids)
    |> assign(:selected_date, selected_date)
    |> assign(:sort_by, sort_by)
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
    effective_today = DateHelpers.effective_today_eastern()

    with %{"selected_date" => selected_date} when is_binary(selected_date) <-
           get_connect_params(socket),
         {:ok, date} <- Date.from_iso8601(selected_date),
         comparison when comparison in [:gt, :eq] <- Date.compare(date, effective_today) do
      selected_date
    else
      _invalid_or_past_date -> nil
    end
  end

  defp get_sort_by_in_local_storage(socket) do
    case get_connect_params(socket) do
      %{"sort_by" => sort_by} when sort_by in ["title", "venue"] -> sort_by
      _default -> "title"
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
              from_date: from_date,
              sort_by: sort_by_atom(socket.assigns[:sort_by])
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
      |> assign(:sort_by, "title")
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
        from_date: from_date,
        sort_by: sort_by_atom(socket.assigns[:sort_by])
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
        from_date: from_date,
        sort_by: sort_by_atom(socket.assigns[:sort_by])
      )

    socket
    |> update_socket_assigns(paged_events, venue_ids)
    |> push_event("clearVenueFilterIdsFromLocalStorage", %{})
    |> noreply()
  end

  @impl true
  def handle_event("sort-changed", %{"sort-by" => sort_by}, socket) do
    sort_by = if sort_by in ["title", "venue"], do: sort_by, else: "title"
    from_date = parse_selected_date(socket.assigns[:selected_date])

    paged_events =
      MusicListings.list_events(
        page: socket.assigns[:current_page],
        venue_ids: socket.assigns[:venue_ids],
        from_date: from_date,
        sort_by: sort_by_atom(sort_by)
      )

    socket
    |> update_socket_assigns(paged_events)
    |> assign(:sort_by, sort_by)
    |> push_event("saveSortByToLocalStorage", %{sort_by: sort_by})
    |> noreply()
  end

  @impl true
  def handle_event("date-filter-changed", %{"date" => date}, socket) do
    selected_date = parse_selected_date(date)

    paged_events =
      MusicListings.list_events(
        page: 1,
        venue_ids: socket.assigns[:venue_ids],
        from_date: selected_date,
        sort_by: sort_by_atom(socket.assigns[:sort_by])
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
    today = Date.to_iso8601(DateHelpers.effective_today_eastern())
    selected_date = parse_selected_date(today)

    paged_events =
      MusicListings.list_events(
        page: 1,
        venue_ids: socket.assigns[:venue_ids],
        from_date: selected_date,
        sort_by: sort_by_atom(socket.assigns[:sort_by])
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
        venue_ids: socket.assigns[:venue_ids],
        sort_by: sort_by_atom(socket.assigns[:sort_by])
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

  defp sort_by_atom("venue"), do: :venue
  defp sort_by_atom(_title), do: :title

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
    <%!-- Desktop filter row: hidden on mobile --%>
    <div
      class="hidden md:flex flex-wrap items-center gap-3 mb-6"
      data-venue-filter-restore="true"
      data-storage-key="venue_ids"
      data-date-filter-restore="true"
      data-date-storage-key="selected_date"
    >
      <.venue_filter for={@venue_filtering_form} venues={@venues} venue_ids={@venue_ids} />
      <.date_filter for={@date_filtering_form} selected_date={@selected_date} />
      <.sort_toggle sort_by={@sort_by} />
    </div>

    <div class="hidden md:block">
      <.venue_filter_status venue_ids={@venue_ids} />
      <.date_filter_status selected_date={@selected_date} />
    </div>

    <%!-- Mobile filter button + chips: hidden on desktop --%>
    <div class="md:hidden mb-4 flex items-start justify-between gap-3">
      <.mobile_filter_button />
      <.mobile_filter_chips
        venue_ids={@venue_ids}
        selected_date={@selected_date}
      />
    </div>

    <%!-- Mobile bottom sheet --%>
    <.bottom_sheet id="mobile-filters">
      <.mobile_venue_filter
        for={@venue_filtering_form}
        venues={@venues}
        venue_ids={@venue_ids}
      />
      <.mobile_date_filter for={@date_filtering_form} selected_date={@selected_date} />
      <.mobile_sort_toggle sort_by={@sort_by} />
    </.bottom_sheet>

    <%= if @loading do %>
      <.loading_indicator />
    <% end %>

    <.events_list events={@events} current_user={@current_user} sort_by={@sort_by} />

    <div class="mt-8 pt-6 border-t border-neutral-800">
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    </div>
    """
  end
end
