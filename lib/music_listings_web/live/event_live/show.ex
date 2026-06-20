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
        socket
        |> assign_event_seo(event)
        |> ok()
      else
        {:ok, push_navigate(socket, to: ~p"/events/#{event.id}/#{canonical_slug}", replace: true)}
      end
    else
      _error -> raise Ecto.NoResultsError, queryable: MusicListingsSchema.Event
    end
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
        [:music_listings, :recently_added, :card_click],
        %{},
        %{event_id: event_id}
      )
    end

    :ok
  end

  defp maybe_track_recently_added_click(_socket, _params), do: :ok

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
