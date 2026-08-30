defmodule MusicListingsWeb.EventLive.Show do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListings.Accounts.User
  alias MusicListingsUtilities.DateHelpers
  alias MusicListingsWeb.AnalyticsTracking
  alias MusicListingsWeb.SEO

  @impl true
  def mount(%{"id" => _id} = params, _session, socket) do
    with {:ok, %{id: id}} <- validate(:show, params),
         {:ok, event} <- MusicListings.fetch_event(id) do
      canonical_slug = SEO.event_slug(event)

      if params["slug"] == canonical_slug do
        rail_enabled? = FunWithFlags.enabled?(:show_recently_added)

        maybe_track_recently_added_click(socket, params, rail_enabled?)
        maybe_track_ticket_link_shown(socket, event, params)

        socket
        |> assign(:ref, params["ref"])
        |> assign(:resale_enabled, FunWithFlags.enabled?(:show_resale_tickets))
        |> assign_flagged(event)
        |> assign_event_seo(event)
        |> ok()
      else
        path = redirect_path(event.id, canonical_slug, params["ref"])
        {:ok, push_navigate(socket, to: path, replace: true)}
      end
    else
      _error -> raise Ecto.NoResultsError, queryable: MusicListingsSchema.Event
    end
  end

  # Carries the ?ref referrer through the slug-canonicalisation redirect so rail
  # attribution survives to the re-mounted (canonical) page. Only appends the
  # param when present, keeping direct visits on a clean canonical URL.
  defp redirect_path(id, slug, nil), do: ~p"/events/#{id}/#{slug}"
  defp redirect_path(id, slug, ref), do: ~p"/events/#{id}/#{slug}?#{[ref: ref]}"

  # Fired when the "Get Tickets" button on the detail page is clicked. The `ref`
  # assign (captured in mount from ?ref=) distinguishes rail-referred visits
  # ("new_this_week") from direct ones, letting us measure the rail conversion
  # funnel: card_click (arrival) → ticket_click (this event).
  @impl true
  def handle_event("event_ticket_click", %{"id" => event_id}, socket) do
    :telemetry.execute(
      [:music_listings, :event, :ticket_click],
      %{},
      %{event_id: event_id, ref: socket.assigns[:ref]}
    )

    noreply(socket)
  end

  # Fired when the TicketNetwork (resale) link on the detail page is clicked.
  # Carries the same `ref` as the primary ticket click so resale clicks can also
  # be attributed to the rail.
  def handle_event("event_resale_click", params, socket) do
    AnalyticsTracking.track_resale_click(params, socket.assigns[:ref])

    noreply(socket)
  end

  # Admin curation controls.  Both actions are authorised in the context, not
  # here - the button is merely hidden from non-admins.
  def handle_event(
        "delete-event",
        %{"id" => event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    current_user
    |> MusicListings.delete_event(event_id)
    |> case do
      {:ok, deleted_event} ->
        # Re-derive the notice so the page immediately says the event is no
        # longer listed, and drop the dismiss button with the flag it resolved.
        socket
        |> assign(:event, %{socket.assigns.event | deleted_at: deleted_event.deleted_at})
        |> assign(:notice, notice_for_event(deleted_event))
        |> assign(:flagged?, false)
        |> noreply()

      _no_change ->
        noreply(socket)
    end
  end

  def handle_event(
        "dismiss-event-flags",
        %{"id" => event_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    current_user
    |> MusicListings.dismiss_event_flags(event_id)
    |> case do
      {:ok, _count} -> socket |> assign(:flagged?, false) |> noreply()
      _no_change -> noreply(socket)
    end
  end

  defparams :show do
    required(:id, :integer)
  end

  # Only admins can act on a flag, so only admins pay for the lookup.
  defp assign_flagged(socket, event) do
    flagged? =
      case socket.assigns[:current_user] do
        %User{role: :admin} -> MusicListings.event_flagged?(event.id)
        _user_or_nil -> false
      end

    assign(socket, :flagged?, flagged?)
  end

  # Emitted when a visitor arrives via a "New This Week" rail card (the rail
  # links carry ?ref=new_this_week). Guarded on connected?/1 so it counts once
  # per arrival. Fired only from the canonical-slug branch of mount/3: the ref is
  # preserved across the canonicalisation redirect (see redirect_path/3), so
  # counting here attributes card_click, ticket_link_shown and ticket_click all
  # to the same canonical mount and avoids double-counting a redirected arrival.
  #
  # Also gated on the rail's own feature flag. Without that, an arrival on a
  # ?ref=new_this_week URL still in circulation - bookmarked, shared, or indexed -
  # counts as a rail click long after the rail stopped rendering, which is exactly
  # what produced a 94% "card CTR" in the week the flag went off. The flag is read
  # once in mount/3 and passed in rather than checked here, per the project's
  # rule on FunWithFlags lookups.
  defp maybe_track_recently_added_click(
         socket,
         %{"ref" => "new_this_week", "id" => event_id},
         true
       ) do
    if connected?(socket) do
      :telemetry.execute(
        [:music_listings, :new_this_week, :card_click],
        %{},
        %{event_id: event_id}
      )
    end

    :ok
  end

  defp maybe_track_recently_added_click(_socket, _params, _rail_enabled?), do: :ok

  # Records that a ticket link was actually presented on the detail page (fires
  # only when the event has a ticket_url). Paired with the event.ticket_click
  # event, this gives an overall detail-page ticket CTR; the `ref` also lets us
  # split rail-referred impressions from direct ones. Guarded on connected?/1 so
  # it counts once per page view, mirroring maybe_track_recently_added_click/2.
  defp maybe_track_ticket_link_shown(socket, event, params) do
    if connected?(socket) and is_binary(event.ticket_url) do
      :telemetry.execute(
        [:music_listings, :event, :ticket_link_shown],
        %{},
        %{event_id: to_string(event.id), ref: params["ref"]}
      )
    end

    :ok
  end

  defp assign_event_seo(socket, event) do
    canonical_path = SEO.event_path(event)
    meta_description = SEO.event_meta_description(event)
    page_title = "#{event.title} — #{event.venue.name}"

    socket
    |> assign(:event, event)
    |> assign(:notice, notice_for_event(event))
    |> assign(:page_title, page_title)
    |> assign(:og_type, "article")
    |> assign(:og_title, page_title)
    |> assign(:meta_description, meta_description)
    |> assign(:og_description, meta_description)
    |> assign(:canonical_url, SEO.canonical_url(canonical_path))
    |> assign(:json_ld, SEO.event_json_ld(event))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="mx-auto max-w-3xl">
      <.event_breadcrumb event={@event} />
      <.event_notice :if={@notice} message={@notice} />
      <.event_header event={@event} />
      <.event_details_list event={@event} />
      <.event_actions
        event={@event}
        show_resale={@resale_enabled}
        current_user={@current_user}
        flagged?={@flagged?}
      />
    </article>
    """
  end

  defp notice_for_event(event) do
    cond do
      Date.before?(event.date, DateHelpers.effective_today_eastern()) ->
        "This event has already taken place."

      event.deleted_at ->
        "This event is no longer listed and may have been cancelled or rescheduled."

      true ->
        nil
    end
  end
end
