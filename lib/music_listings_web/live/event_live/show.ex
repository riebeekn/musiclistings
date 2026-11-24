defmodule MusicListingsWeb.EventLive.Show do
  use MusicListingsWeb, :live_view
  use Goal

  import MusicListingsWeb.EventComponents,
    only: [duplicate_event_urls?: 2, format_age_restriction: 1, format_price: 2]

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

  attr :message, :string, required: true

  defp event_notice(assigns) do
    ~H"""
    <div
      role="status"
      class="mb-6 rounded border border-amber-400/50 bg-amber-400/10 px-4 py-3 font-mono text-sm text-amber-300"
    >
      {@message}
    </div>
    """
  end

  attr :event, :any, required: true

  defp event_breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="kicker mb-6">
      <ol class="flex flex-wrap items-center gap-2">
        <li>
          <.link navigate={~p"/events"} class="transition-colors hover:text-spotlight">Events</.link>
        </li>
        <li aria-hidden="true" class="text-spotlight">/</li>
        <li :if={@event.venue}>
          <.link
            navigate={~p"/events/venue/#{@event.venue.id}"}
            class="transition-colors hover:text-spotlight"
          >
            {@event.venue.name}
          </.link>
        </li>
        <li :if={@event.venue} aria-hidden="true" class="text-spotlight">/</li>
        <li class="max-w-[50vw] truncate text-paper">{@event.title}</li>
      </ol>
    </nav>
    """
  end

  attr :event, :any, required: true

  defp event_header(assigns) do
    ~H"""
    <p :if={@event.venue} class="kicker text-spotlight-deep">
      <.link navigate={~p"/events/venue/#{@event.venue.id}"} class="hover:text-spotlight">
        {@event.venue.name}
      </.link>
    </p>

    <%!-- break-words is load-bearing on a phone: titles routinely carry unbreakable tokens
          like "Belew/Vai/Levin/Bozzio", and browsers offer no break opportunity at a slash,
          so at 48px one of those pushes the page wider than the screen.

          leading-[1.05], not the tighter leading used by .headline: this title is mixed
          case, so it has descenders. In Big Shoulders Display a 'g' reaches -0.140em and a
          cap 'T' reaches +0.800em, so consecutive lines only clear when line-height >=
          0.94em. The old leading-[0.9] overlapped them by 0.04em (~2px at text-5xl) and
          "…: The / Tour" collided. 1.05 is the shared value for mixed-case display type
          across the app (see the event card titles). .headline can stay far tighter because
          it is uppercase — no descenders at all. --%>
    <h1 class="mt-3 font-display text-5xl font-bold leading-[1.05] break-words text-paper sm:text-6xl lg:text-7xl">
      {@event.title}
    </h1>
    <p
      :if={@event.openers != []}
      class="mt-3 font-display text-2xl font-medium break-words text-paper-dim"
    >
      with {Enum.join(@event.openers, ", ")}
    </p>
    """
  end

  attr :event, :any, required: true

  defp event_details_list(assigns) do
    ~H"""
    <dl class="mt-8 grid grid-cols-2 border-t border-hairline sm:grid-cols-4">
      <.detail label="Date" class="font-display text-xl font-bold text-paper">
        <time datetime={Date.to_iso8601(@event.date)}>
          {DateHelpers.format_date(@event.date)}
        </time>
      </.detail>
      <.detail :if={@event.time} label="Showtime" class="font-mono text-lg text-paper">
        {DateHelpers.format_time(@event.time)}
      </.detail>
      <.detail
        :if={@event.price_format != :unknown}
        label="Price"
        class="font-mono text-lg text-spotlight"
      >
        {format_price(@event, :long)}
      </.detail>
      <.detail
        :if={@event.age_restriction != :unknown}
        label="Age"
        class="font-mono text-lg text-paper"
      >
        {format_age_restriction(@event.age_restriction)}
      </.detail>
      <div :if={@event.venue} class="col-span-2 border-b border-hairline py-4 sm:col-span-4">
        <dt class="kicker">Venue</dt>
        <dd class="mt-1.5">
          <.link
            navigate={~p"/events/venue/#{@event.venue.id}"}
            class="font-display text-xl font-bold text-paper transition-colors hover:text-spotlight"
          >
            {@event.venue.name}
          </.link>
          <div class="mt-0.5 font-mono text-sm text-paper-dim">
            {@event.venue.street}, {@event.venue.city} {@event.venue.province}
          </div>
        </dd>
      </div>
    </dl>
    """
  end

  attr :label, :string, required: true
  attr :class, :string, required: true, doc: "the value's font, size and colour"
  slot :inner_block, required: true

  defp detail(assigns) do
    ~H"""
    <div class="border-b border-hairline py-4 pr-4 sm:[&:not(:nth-child(4n))]:border-r sm:[&:not(:nth-child(4n+1))]:pl-4">
      <dt class="kicker">{@label}</dt>
      <dd class={["mt-1.5", @class]}>{render_slot(@inner_block)}</dd>
    </div>
    """
  end

  attr :event, :any, required: true
  attr :current_user, :any, default: nil
  attr :flagged?, :boolean, default: false

  defp event_actions(assigns) do
    ~H"""
    <div class="mt-8 flex flex-wrap items-center gap-3">
      <a
        :if={@event.ticket_url}
        href={MusicListings.Affiliate.maybe_wrap_affiliate_link(@event.ticket_url)}
        class="inline-flex h-9 items-center justify-center gap-x-2 rounded bg-spotlight px-4 font-mono text-xs font-medium uppercase tracking-widest text-ink transition-colors hover:bg-spotlight-deep"
        target="_blank"
        rel="noopener sponsored"
        phx-click="event_ticket_click"
        phx-value-id={@event.id}
      >
        <.icon name="hero-ticket-solid" class="size-4" /> Tickets
      </a>
      <a
        :if={
          @event.details_url &&
            !duplicate_event_urls?(@event.ticket_url, @event.details_url)
        }
        href={@event.details_url}
        class="inline-flex h-9 items-center justify-center gap-x-2 rounded border border-hairline bg-ink px-4 font-mono text-xs font-medium uppercase tracking-widest text-paper transition-colors hover:bg-ink-3"
        target="_blank"
        rel="noopener"
      >
        <.icon
          name="hero-information-circle-solid"
          class="size-4"
        /> Venue page
      </a>
      <.when_admin current_user={@current_user}>
        <button
          phx-click="delete-event"
          phx-value-id={@event.id}
          data-confirm="Are you sure?"
          class="inline-flex h-9 items-center justify-center rounded border border-hairline px-4 font-mono text-xs font-medium uppercase tracking-widest text-paper-dim transition-colors hover:border-ember hover:text-ember"
        >
          Delete
        </button>
        <button
          :if={@flagged?}
          phx-click="dismiss-event-flags"
          phx-value-id={@event.id}
          class="inline-flex h-9 items-center justify-center rounded border border-hairline px-4 font-mono text-xs font-medium uppercase tracking-widest text-paper-dim transition-colors hover:border-paper-dim hover:text-paper"
        >
          Not an issue
        </button>
      </.when_admin>
    </div>
    """
  end
end
