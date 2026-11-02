defmodule MusicListingsWeb.EventLive.Show do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListings.Accounts.User
  alias MusicListingsUtilities.DateHelpers
  alias MusicListingsWeb.SEO

  @impl true
  def mount(%{"id" => _id} = params, _session, socket) do
    with {:ok, %{id: id}} <- validate(:show, params),
         {:ok, event} <- MusicListings.fetch_event(id) do
      canonical_slug = SEO.event_slug(event)

      if params["slug"] == canonical_slug do
        maybe_track_ticket_link_shown(socket, event)

        socket
        |> assign_flagged(event)
        |> assign_event_seo(event)
        |> ok()
      else
        {:ok, push_navigate(socket, to: ~p"/events/#{event.id}/#{canonical_slug}", replace: true)}
      end
    else
      _error -> raise Ecto.NoResultsError, queryable: MusicListingsSchema.Event
    end
  end

  # Fired when the "Get Tickets" button on the detail page is clicked.
  @impl true
  def handle_event("event_ticket_click", %{"id" => event_id}, socket) do
    :telemetry.execute(
      [:music_listings, :event, :ticket_click],
      %{},
      %{event_id: event_id}
    )

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

  # Records that a ticket link was actually presented on the detail page (fires
  # only when the event has a ticket_url). Paired with the event.ticket_click
  # event, this gives an overall detail-page ticket CTR. Guarded on connected?/1
  # so it counts once per page view.
  defp maybe_track_ticket_link_shown(socket, event) do
    if connected?(socket) and is_binary(event.ticket_url) do
      :telemetry.execute(
        [:music_listings, :event, :ticket_link_shown],
        %{},
        %{event_id: to_string(event.id)}
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
