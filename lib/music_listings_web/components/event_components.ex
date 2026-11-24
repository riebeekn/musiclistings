defmodule MusicListingsWeb.EventComponents do
  @moduledoc """
  Components for displaying listed events, shared by the events and venue pages, and
  the formatting helpers the event page shares with them.
  """

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MusicListingsWeb.Endpoint,
    router: MusicListingsWeb.Router,
    statics: MusicListingsWeb.static_paths()

  import MusicListingsWeb.CoreComponents, only: [icon: 1, when_admin: 1]

  alias MusicListingsUtilities.DateHelpers
  alias MusicListingsWeb.SEO

  @doc """
  Renders a list of events for the passed in events

  ## Example

  <.events_list events={@events} current_user={current_user} sort_by="title" />
  """
  attr :events, :list, required: true
  attr :current_user, :any, required: true
  attr :sort_by, :string, default: "title"

  def events_list(assigns) do
    ~H"""
    <div>
      <%= for {date, events} <- @events do %>
        <.events_date_header date={date} />
        <div class="mb-14">
          <%= if @sort_by == "venue" do %>
            <%= for {venue, venue_events} <- group_events_by_venue(events) do %>
              <.venue_grouped_card
                venue={venue}
                events={venue_events}
                current_user={@current_user}
              />
            <% end %>
          <% else %>
            <%= for event <- events do %>
              <.event_card event={event} current_user={@current_user} />
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp group_events_by_venue(events) do
    events
    |> Enum.group_by(& &1.venue)
    |> Enum.map(fn {venue, venue_events} ->
      {venue, sort_events_by_time(venue_events)}
    end)
    |> Enum.sort_by(fn {venue, _events} -> venue.name end)
  end

  defp sort_events_by_time(events) do
    Enum.sort_by(events, fn event ->
      first_time = event.showtimes |> List.first() |> then(& &1.time)
      {DateHelpers.night_ordered_time_key(first_time), event.title}
    end)
  end

  @doc """
  Renders a list of events for the passed in events, specific to a single venue

  ## Example

  <.venue_events_list events={@events} current_user={@current_user} />
  """
  attr :events, :list, required: true
  attr :current_user, :any, required: true

  def venue_events_list(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= for {date, events} <- @events do %>
        <.venue_date_grouped_card
          date={date}
          events={sort_events_by_time(events)}
          current_user={@current_user}
        />
      <% end %>
    </div>
    """
  end

  defp events_date_header(assigns) do
    ~H"""
    <div id={"date-#{@date}"} class="flex items-end gap-5 pt-16 pb-5 first:pt-4 scroll-mt-28">
      <span class="mb-2 hidden h-2.5 w-2.5 shrink-0 bg-spotlight sm:block"></span>
      <h2 class="headline text-4xl whitespace-nowrap text-paper sm:text-5xl">
        <time datetime={@date}>{DateHelpers.format_date(@date)}</time>
      </h2>
      <div class="mb-3 h-px flex-1 bg-hairline"></div>
    </div>
    """
  end

  attr :event, :any, required: true
  attr :current_user, :any, required: true
  attr :show_date, :boolean, default: false

  defp event_card(assigns) do
    ~H"""
    <article class="group border-b border-hairline transition-colors duration-200 hover:bg-ink-2/60">
      <div class="grid grid-cols-1 gap-x-8 gap-y-3 px-1 py-6 sm:grid-cols-[1fr_auto] sm:items-start sm:px-3">
        <div class="min-w-0">
          <div class="mb-2 flex flex-wrap items-center gap-2.5">
            <span
              :if={@show_date}
              class="inline-flex items-center gap-1 font-mono text-xs uppercase tracking-wider text-paper"
            >
              <.icon name="hero-calendar" class="size-3.5" />
              {DateHelpers.format_date(@event.date)}
            </span>
            <.event_venue venue={@event.venue} />
            <.event_age_restriction age_restriction={@event.age_restriction} />
          </div>
          <h3 class="font-display text-2xl font-bold leading-[1.05] text-paper transition-colors group-hover:text-spotlight sm:text-3xl">
            <.event_title_link event_info={@event}>
              {@event.title}
            </.event_title_link>
          </h3>
          <p :if={@event.openers != []} class="mt-1.5 font-display text-lg font-medium text-paper-dim">
            with {@event.openers |> Enum.join(", ")}
          </p>
        </div>
        <.showtimes event={@event} current_user={@current_user} />
      </div>
    </article>
    """
  end

  defp venue_grouped_card(assigns) do
    ~H"""
    <article class="border-b border-hairline py-6">
      <div class="mb-3 flex items-center gap-3 px-1 sm:px-3">
        <.event_venue venue={@venue} />
        <div class="h-px flex-1 bg-hairline"></div>
      </div>
      <%= for event <- @events do %>
        <.grouped_event_row event={event} current_user={@current_user} />
      <% end %>
    </article>
    """
  end

  defp venue_date_grouped_card(assigns) do
    ~H"""
    <article class="border-b border-hairline py-6">
      <h3 class="mb-3 px-1 font-display text-2xl font-bold text-spotlight sm:px-3">
        <time datetime={@date}>{DateHelpers.format_date(@date)}</time>
      </h3>
      <%= for event <- @events do %>
        <.grouped_event_row event={event} current_user={@current_user} />
      <% end %>
    </article>
    """
  end

  attr :event, :any, required: true
  attr :current_user, :any, required: true

  defp grouped_event_row(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-x-8 gap-y-2 px-1 py-3 sm:grid-cols-[1fr_auto] sm:items-start sm:px-3">
      <div class="min-w-0">
        <div class="flex flex-wrap items-center gap-2.5">
          <h4 class="group inline font-display text-xl font-bold leading-tight text-paper sm:text-2xl">
            <.event_title_link event_info={@event}>
              <span class="transition-colors group-hover:text-spotlight">{@event.title}</span>
            </.event_title_link>
          </h4>
          <.event_age_restriction age_restriction={@event.age_restriction} />
        </div>
        <p :if={@event.openers != []} class="mt-1 font-display text-base font-medium text-paper-dim">
          with {@event.openers |> Enum.join(", ")}
        </p>
      </div>
      <.showtimes event={@event} current_user={@current_user} />
    </div>
    """
  end

  attr :event, :any, required: true
  attr :current_user, :any, required: true

  defp showtimes(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 sm:items-end">
      <%= for showtime <- @event.showtimes do %>
        <div
          id={"event-#{showtime.event_id}"}
          class="flex flex-wrap items-center gap-2 sm:justify-end"
        >
          <.event_time time={showtime.time} />
          <.event_ticket_url
            ticket_url={showtime.ticket_url}
            price_format={@event.price_format}
            price_lo={@event.price_lo}
            price_hi={@event.price_hi}
          />
          <.event_details_url
            details_url={showtime.details_url}
            ticket_url={showtime.ticket_url}
          />
          <.delete_event_link current_user={@current_user} event_id={showtime.event_id} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :event_info, :any, required: true
  slot :inner_block, required: true

  defp event_title_link(assigns) do
    first_show = List.first(assigns.event_info.showtimes)
    slug = SEO.slugify(assigns.event_info.title || "event")
    event_id = first_show && first_show.event_id

    navigate = event_id && ~p"/events/#{event_id}/#{slug}"

    assigns = assign(assigns, event_id: event_id, navigate: navigate)

    ~H"""
    <.link :if={@event_id} navigate={@navigate} class="transition-colors">
      {render_slot(@inner_block)}
    </.link>
    <span :if={!@event_id}>{render_slot(@inner_block)}</span>
    """
  end

  defp event_venue(assigns) do
    ~H"""
    <a
      href={~p"/events/venue/#{@venue.id}"}
      class="kicker text-spotlight-deep transition-colors hover:text-spotlight"
    >
      {@venue.name}
    </a>
    """
  end

  defp event_age_restriction(%{age_restriction: :unknown} = assigns), do: ~H""

  defp event_age_restriction(assigns) do
    ~H"""
    <span class="inline-flex items-center border border-amber-400/50 text-amber-400 px-2 py-0.5 font-mono text-xs uppercase tracking-wider">
      {format_age_restriction(@age_restriction)}
    </span>
    """
  end

  @doc """
  Formats an event's age restriction for display, e.g. "19+".
  """
  def format_age_restriction(:all_ages), do: "All Ages"
  def format_age_restriction(:eighteen_plus), do: "18+"
  def format_age_restriction(:nineteen_plus), do: "19+"

  defp event_time(%{time: nil} = assigns), do: ~H""

  defp event_time(assigns) do
    ~H"""
    <time
      datetime={Time.to_iso8601(@time)}
      class="font-mono text-xs text-paper-dim [font-variant-numeric:tabular-nums]"
    >
      {DateHelpers.format_time(@time)}
    </time>
    """
  end

  defp event_ticket_url(assigns) do
    ~H"""
    <%= if @ticket_url do %>
      <a
        href={MusicListings.Affiliate.maybe_wrap_affiliate_link(@ticket_url)}
        class="inline-flex items-center gap-1 font-mono text-[0.7rem] uppercase tracking-wider text-spotlight bg-spotlight/10 ring-1 ring-inset ring-spotlight/30 px-3 py-1 transition-colors hover:bg-spotlight hover:text-ink"
        target="_blank"
        rel="noopener sponsored"
      >
        <.icon
          name="hero-ticket-solid"
          class="size-3.5"
        /> Tickets
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </a>
    <% end %>
    <%= if @price_format != :unknown && !@ticket_url do %>
      <span class="inline-flex items-center font-mono text-[0.7rem] uppercase tracking-wider text-spotlight border border-spotlight/40 px-3 py-1">
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </span>
    <% end %>
    """
  end

  @doc """
  Whether an event's ticket and details links go to the same place.
  """
  # A handful of venues (Burdock, Sneaky Dee's, Standard Time, ...) expose a single
  # URL that serves as both the ticket link and the event page.  Two chips pointing at
  # one destination is noise, so the Info chip yields to the richer Tickets chip, which
  # also carries the price, the affiliate wrapping and the click tracking.
  # `ticket_url != ""` keeps this decoupled from the separate empty-string bug: a blank
  # ticket url is treated as absent here rather than as a match against a blank details
  # url, so the Info chip keeps rendering exactly as it does today.
  def duplicate_event_urls?(ticket_url, details_url)
      when is_binary(ticket_url) and is_binary(details_url) and ticket_url != "",
      do: ticket_url == details_url

  def duplicate_event_urls?(_ticket_url, _details_url), do: false

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    assigns = assign_new(assigns, :ticket_url, fn -> nil end)

    ~H"""
    <a
      :if={!duplicate_event_urls?(@ticket_url, @details_url)}
      href={@details_url}
      class="inline-flex items-center gap-1 font-mono text-[0.7rem] uppercase tracking-wider text-paper-dim ring-1 ring-inset ring-hairline px-3 py-1 transition-colors hover:text-paper hover:ring-paper-dim"
      target="_blank"
      rel="noopener"
    >
      <.icon
        name="hero-information-circle-solid"
        class="size-3.5"
      /> Info
    </a>
    """
  end

  defp event_price(%{price_format: :unknown} = assigns), do: ~H""

  defp event_price(assigns) do
    ~H"""
    {format_price(assigns, :short)}
    """
  end

  @doc """
  Formats an event's price for display. `:long` spells out e.g. "Pay what you can".
  """
  def format_price(%{price_format: :free}, :short), do: "FREE"
  def format_price(%{price_format: :free}, :long), do: "Free"
  def format_price(%{price_format: :pwyc}, :short), do: "PWYC"
  def format_price(%{price_format: :pwyc}, :long), do: "Pay what you can"
  def format_price(%{price_format: :fixed, price_lo: lo}, _style), do: "$#{lo}"
  def format_price(%{price_format: :variable, price_lo: lo}, _style), do: "$#{lo}+"

  def format_price(%{price_format: :range, price_lo: lo, price_hi: hi}, _style),
    do: "$#{lo} – $#{hi}"

  def format_price(_event, _style), do: ""

  defp delete_event_link(assigns) do
    ~H"""
    <.when_admin current_user={@current_user}>
      <button
        phx-click="delete-event"
        phx-value-id={@event_id}
        data-confirm="Are you sure?"
        class="font-mono text-[0.7rem] uppercase tracking-wider text-paper-dim transition-colors hover:text-ember"
      >
        Delete
      </button>
    </.when_admin>
    """
  end
end
