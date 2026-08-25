defmodule MusicListingsWeb.EventLive.Index do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListingsUtilities.DateHelpers
  alias MusicListingsWeb.AnalyticsTracking
  alias MusicListingsWeb.SEO

  # Cap on the free-text search term.  Anything longer is almost certainly not a real
  # title, and it bounds the LIKE pattern we hand to Postgres.
  @max_search_length 100

  @impl true
  def mount(_params, _session, socket) do
    venue_ids = get_venue_ids_in_local_storage(socket)

    selected_date =
      get_selected_date_in_local_storage(socket) ||
        Date.to_iso8601(DateHelpers.effective_today_eastern())

    sort_by = get_sort_by_in_local_storage(socket)

    venues =
      MusicListings.list_venues(
        restrict_to_pulled_venues?: false,
        only_with_upcoming_events?: true
      )

    socket
    |> assign(:venues, venues)
    |> assign(:venue_ids, venue_ids)
    |> assign(:selected_date, selected_date)
    |> assign(:sort_by, sort_by)
    |> assign(:just_added_enabled, FunWithFlags.enabled?(:show_recently_added))
    |> assign(:resale_enabled, FunWithFlags.enabled?(:show_resale_tickets))
    |> assign(:venue_filtering_form, to_form(%{}))
    |> assign(:date_filtering_form, to_form(%{}))
    |> assign(:search_form, to_form(%{}))
    |> assign(:search_term, "")
    |> assign(:search_suggestions, [])
    |> assign(:page_title, "Toronto Live Music Events")
    |> assign(
      :meta_description,
      "Browse upcoming live music events in Toronto — concerts, club shows, and festivals from dozens of venues, updated daily."
    )
    |> assign(:canonical_url, SEO.canonical_url("/events"))
    |> assign(:new_this_week_tracked, false)
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
    venue_ids = socket.assigns[:venue_ids] || []

    case validate(:index, params) do
      {:ok, normalized_params} ->
        paged_events = list_events_for(socket, page: normalized_params[:page])

        if connected?(socket) do
          recently_added = recently_added_events(socket)

          socket
          |> update_socket_assigns(paged_events, venue_ids)
          |> assign(:new_this_week, recently_added)
          |> assign(:loading, false)
          |> maybe_track_recently_added_shown(recently_added)
          |> noreply()
        else
          socket
          |> assign(:events, [])
          |> assign(:new_this_week, [])
          |> assign(:current_page, 1)
          |> assign(:total_pages, 0)
          |> assign(:loading, true)
          |> assign(:json_ld, json_ld_for(paged_events))
          |> noreply()
        end

      _error ->
        socket
        |> push_navigate(to: ~p"/events")
        |> noreply()
    end
  end

  defp json_ld_for(paged_events) do
    paged_events.events
    |> SEO.grouped_events_to_list_items()
    |> SEO.event_list_json_ld()
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

    socket
    |> assign(:venue_ids, venue_ids)
    |> reload_events()
    |> push_event("saveVenueFilterIdsToLocalStorage", %{venue_ids: venue_ids})
    |> noreply()
  end

  @impl true
  def handle_event("clear-venue-filtering", _params, socket) do
    socket
    |> assign(:venue_ids, [])
    |> reload_events()
    |> push_event("clearVenueFilterIdsFromLocalStorage", %{})
    |> noreply()
  end

  # Search is the one filter that lives nowhere but socket assigns.  The venue/date/sort
  # filters persist in localStorage because they describe how you like to browse; a search
  # term describes what you are looking for right now, and it should not outlive the visit.
  # Keeping it out of the URL is what makes a refresh or a back-navigation return the full
  # listing instead of yesterday's query.  Paging still works: the pager patches, so assigns
  # survive, and list_events_for/2 reads the term back out of them.
  @impl true
  def handle_event("search", %{"q" => search_term}, socket) do
    search_term = normalize_search_term(search_term)

    socket
    |> assign(:search_term, search_term)
    |> assign(:search_suggestions, suggestions_for(socket, search_term))
    |> reload_events(page: 1)
    |> noreply()
  end

  # Enter commits whatever has been typed.  It needs its own handler rather than reusing
  # "search": that one reoffers the suggestions it just rendered, so the dropdown stays
  # put and pressing Enter looks like it did nothing.  Submitting also flushes any pending
  # debounce, so a term typed and entered inside 300ms still reaches the listing.
  @impl true
  def handle_event("submit-search", %{"q" => search_term}, socket) do
    search_term = normalize_search_term(search_term)

    socket
    |> assign(:search_term, search_term)
    |> assign(:search_suggestions, [])
    |> reload_events(page: 1)
    |> noreply()
  end

  @impl true
  def handle_event("clear-search", _params, socket) do
    socket
    |> assign(:search_term, "")
    |> assign(:search_suggestions, [])
    |> reload_events(page: 1)
    |> noreply()
  end

  @impl true
  def handle_event("dismiss-suggestions", _params, socket) do
    socket
    |> assign(:search_suggestions, [])
    |> noreply()
  end

  @impl true
  def handle_event("sort-changed", %{"sort-by" => sort_by}, socket) do
    sort_by = if sort_by in ["title", "venue"], do: sort_by, else: "title"

    socket
    |> assign(:sort_by, sort_by)
    |> reload_events()
    |> push_event("saveSortByToLocalStorage", %{sort_by: sort_by})
    |> noreply()
  end

  @impl true
  def handle_event("date-filter-changed", %{"date" => date}, socket) do
    selected_date = parse_selected_date(date)
    selected_date_string = if selected_date, do: Date.to_iso8601(selected_date), else: ""

    socket
    |> assign(:selected_date, selected_date_string)
    |> reload_events(page: 1)
    |> push_event("saveDateFilterToLocalStorage", %{selected_date: selected_date_string})
    |> noreply()
  end

  @impl true
  def handle_event("clear-date-filter", _params, socket) do
    today = Date.to_iso8601(DateHelpers.effective_today_eastern())

    socket
    |> assign(:selected_date, today)
    |> reload_events(page: 1)
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

    socket
    |> reload_events()
    |> assign(:new_this_week, recently_added_events(socket))
    |> noreply()
  end

  # Fired when a TicketNetwork (resale) chip in a list row is clicked. There is
  # no `ref` on this page, so these are recorded with a nil referrer.
  def handle_event("event_resale_click", params, socket) do
    AnalyticsTracking.track_resale_click(params, socket.assigns[:ref])

    noreply(socket)
  end

  defp recently_added_events(socket) do
    if socket.assigns.just_added_enabled do
      MusicListings.list_recently_added_events(limit: 12)
    else
      []
    end
  end

  # Records a single "rail shown" impression per connected session — guarded so
  # pagination/filter patches (which re-run handle_params) don't re-count it.
  defp maybe_track_recently_added_shown(socket, recently_added) do
    if socket.assigns.just_added_enabled and recently_added != [] and
         not socket.assigns.new_this_week_tracked do
      :telemetry.execute(
        [:music_listings, :new_this_week, :shown],
        %{},
        %{}
      )

      assign(socket, :new_this_week_tracked, true)
    else
      socket
    end
  end

  # Single source of truth for the listing query.  Every filter is read back out of
  # assigns, so a handler only has to assign the value it changed before calling this -
  # that is what stops a newly added filter from being silently dropped by the handlers
  # that forgot to thread it through.  `overrides` is for the cases that also reset paging.
  # The term arrives straight off the form now that it is not a URL param, so this is the
  # only thing bounding it before it reaches the LIKE pattern.  The input carries a
  # matching maxlength, but that is a client-side courtesy, not a guarantee.
  defp normalize_search_term(nil), do: ""

  defp normalize_search_term(search_term) do
    search_term
    |> String.trim()
    |> String.slice(0, @max_search_length)
  end

  # Suggestions only make sense once there is something to disambiguate; a one-character
  # term matches most of the catalogue.
  defp suggestions_for(_socket, search_term) when byte_size(search_term) < 2, do: []

  defp suggestions_for(_socket, search_term) do
    MusicListings.search_event_titles(search_term)
  end

  defp list_events_for(socket, overrides) do
    [
      page: socket.assigns[:current_page],
      venue_ids: socket.assigns[:venue_ids] || [],
      from_date: parse_selected_date(socket.assigns[:selected_date]),
      sort_by: sort_by_atom(socket.assigns[:sort_by]),
      search: socket.assigns[:search_term]
    ]
    |> Keyword.merge(overrides)
    |> MusicListings.list_events()
  end

  defp reload_events(socket, overrides \\ []) do
    update_socket_assigns(socket, list_events_for(socket, overrides))
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
    <%!-- MASTHEAD --%>
    <section class={if @just_added_enabled, do: "mb-5", else: "mb-6"}>
      <p class="kicker flex items-center gap-2">
        <span class="inline-block h-2 w-8 bg-spotlight"></span> Toronto · Live Music Listings
      </p>
      <h1 class="headline mt-4 text-[3.25rem] text-paper sm:text-7xl lg:text-8xl">
        What's <span class="text-spotlight glow">On</span> <br class="hidden sm:block" />Tonight
      </h1>
      <p class={[
        "max-w-xl text-sm leading-relaxed text-paper-dim sm:text-base",
        if(@just_added_enabled, do: "mt-4", else: "mt-5")
      ]}>
        Every show worth leaving the house for — concerts, club nights and DIY gigs
        from dozens of venues across the city, refreshed daily.
      </p>
    </section>

    <%!-- SEARCH: one block for both breakpoints, high enough on the page that the
          typeahead opens above the on-screen keyboard on a phone. --%>
    <section class={if @just_added_enabled, do: "mb-6", else: "mb-8"}>
      <.search_bar
        for={@search_form}
        search_term={@search_term}
        suggestions={@search_suggestions}
      />
    </section>

    <%!-- Just Added rail (feature-flagged) --%>
    <.recently_added_peek_rail_tight
      :if={@just_added_enabled}
      events={@new_this_week}
      current_user={@current_user}
    />

    <%!-- Desktop filter bar --%>
    <div
      class={["hidden md:block", if(@just_added_enabled, do: "mb-4", else: "mb-8")]}
      data-venue-filter-restore="true"
      data-storage-key="venue_ids"
      data-date-filter-restore="true"
      data-date-storage-key="selected_date"
    >
      <div class={[
        "flex flex-wrap items-end gap-5 border-t border-hairline",
        if(@just_added_enabled, do: "pt-4", else: "pt-5")
      ]}>
        <.filter_field label="Venues">
          <.venue_filter for={@venue_filtering_form} venues={@venues} venue_ids={@venue_ids} />
        </.filter_field>
        <.filter_field label="When">
          <.date_filter for={@date_filtering_form} selected_date={@selected_date} />
        </.filter_field>
        <.filter_field label="Sort by">
          <.sort_toggle sort_by={@sort_by} />
        </.filter_field>
      </div>
    </div>

    <div class="hidden md:block">
      <.venue_filter_status venue_ids={@venue_ids} />
      <.date_filter_status selected_date={@selected_date} />
    </div>

    <%!-- Mobile filter button + chips: hidden on desktop --%>
    <div class={[
      "md:hidden flex items-start justify-between gap-3 border-t border-hairline",
      if(@just_added_enabled, do: "mb-3 pt-4", else: "mb-4 pt-5")
    ]}>
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

    <.no_results :if={!@loading and @events == []} search_term={@search_term} />

    <.events_list
      events={@events}
      current_user={@current_user}
      sort_by={@sort_by}
      show_resale={@resale_enabled}
    />

    <div class={[
      "border-t border-hairline",
      if(@just_added_enabled, do: "mt-8 pt-5", else: "mt-10 pt-6")
    ]}>
      <.pager current_page={@current_page} total_pages={@total_pages} path={~p"/events"} />
    </div>
    """
  end

  attr :search_term, :string, default: ""

  # The listing renders nothing at all for an empty result set, which reads as a broken
  # page.  The date filter is the usual culprit: from_date defaults to today, so a search
  # for a band who played last week matches rows that are already filtered out.
  defp no_results(assigns) do
    ~H"""
    <div class="border-t border-hairline py-14 text-center">
      <p class="headline text-2xl text-paper">
        <%= if @search_term == "" do %>
          No upcoming events
        <% else %>
          No upcoming events match “{@search_term}”
        <% end %>
      </p>
      <p class="mx-auto mt-3 max-w-md text-sm leading-relaxed text-paper-dim">
        <%= if @search_term == "" do %>
          Try clearing your venue or date filters.
        <% else %>
          Try a different spelling, or clear your venue and date filters — search only looks at
          upcoming shows.
        <% end %>
      </p>
      <button
        :if={@search_term != ""}
        type="button"
        phx-click="clear-search"
        class="mt-6 inline-flex h-9 items-center justify-center rounded bg-spotlight px-4 font-mono text-xs font-medium uppercase tracking-widest text-ink transition-colors hover:bg-spotlight-deep"
      >
        Clear search
      </button>
    </div>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp filter_field(assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5">
      <span class="kicker">{@label}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
