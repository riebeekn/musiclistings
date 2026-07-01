defmodule MusicListingsWeb.EventLive.Show do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListingsUtilities.DateHelpers
  alias MusicListingsWeb.SEO

  @impl true
  def mount(%{"id" => _id} = params, _session, socket) do
    maybe_track_recently_added_click(socket, params)

    with {:ok, %{id: id}} <- validate(:show, params),
         {:ok, event} <- MusicListings.fetch_event(id) do
      canonical_slug = SEO.event_slug(event)

      if params["slug"] == canonical_slug do
        maybe_track_ticket_link_shown(socket, event, params)

        socket
        |> assign(:ref, params["ref"])
        |> assign_event_seo(event)
        |> ok()
      else
        {:ok, push_navigate(socket, to: ~p"/events/#{event.id}/#{canonical_slug}", replace: true)}
      end
    else
      _error -> raise Ecto.NoResultsError, queryable: MusicListingsSchema.Event
    end
  end

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

  defparams :show do
    required(:id, :integer)
  end

  # Emitted when a visitor arrives via a "New This Week" rail card (the rail
  # links carry ?ref=new_this_week). Guarded on connected?/1 so it counts once
  # per arrival, and fired before any slug-canonicalisation redirect.
  defp maybe_track_recently_added_click(socket, %{"ref" => "new_this_week", "id" => event_id}) do
    if connected?(socket) do
      :telemetry.execute(
        [:music_listings, :new_this_week, :card_click],
        %{},
        %{event_id: event_id}
      )
    end

    :ok
  end

  defp maybe_track_recently_added_click(_socket, _params), do: :ok

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
      <.event_actions event={@event} />
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
