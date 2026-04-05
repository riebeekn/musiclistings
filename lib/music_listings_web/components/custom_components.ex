defmodule MusicListingsWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.
  """

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MusicListingsWeb.Endpoint,
    router: MusicListingsWeb.Router,
    statics: MusicListingsWeb.static_paths()

  alias MusicListings.Accounts.User
  alias MusicListingsUtilities.DateHelpers
  alias Phoenix.LiveView.JS

  @doc """
  Scopes the inner element to an admin user, declining to render
  it for non-admin users

  ## Examples

  <.when_admin current_user={@current_user}>
    I will only render if a user is logged in and is an admin.
  </.when_admin>
  """
  attr :current_user, :any, required: true
  slot :inner_block, required: true

  def when_admin(assigns) do
    ~H"""
    <%= if admin?(@current_user) do %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  defp admin?(%User{role: :admin}), do: true
  defp admin?(_user_or_nil), do: false

  @doc """
  Renders a page header with an optional description

  ## Examples

  <.page_header header="Events" />
  <.page_header header="Venues" description="Tracking events for the following venues." />
  """
  attr :header, :string, required: true
  attr :description, :string, default: nil

  def page_header(assigns) do
    ~H"""
    <div class="min-w-0 flex-1">
      <h1 class="font-display text-3xl font-bold leading-7 text-neutral-50 sm:truncate sm:text-4xl sm:tracking-tight">
        {@header}
      </h1>
      <p :if={@description} class="mt-2 text-sm text-neutral-400">
        {@description}
      </p>
    </div>
    """
  end

  @doc """
  Renders a CTA section

  ## Examples

  <.cta header="Get in touch">
    <p>We'd love to hear from you!</p>
  </.cta>
  """

  attr :header, :string, required: true
  slot :inner_block, required: true

  def cta(assigns) do
    ~H"""
    <div class="relative px-6 pt-6 pb-8 lg:static lg:px-8 lg:py-48">
      <div class="mx-auto max-w-xl lg:mx-0 lg:max-w-lg">
        <h1 class="font-display text-pretty text-4xl font-bold tracking-tight text-neutral-50 sm:text-5xl">
          {@header}
        </h1>
        <div class="text-lg/8 text-neutral-400 mt-6 space-y-6">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button link

  ## Example

  <.button_link label="Prev page" url={~p"/events"} icon_name="hero-arrow-left" icon_position={:left} />
  """
  attr :label, :string, required: true
  attr :url, :string, required: true
  attr :icon_name, :string, default: nil
  attr :icon_position, :atom, default: :right

  def button_link(assigns) do
    ~H"""
    <.link
      patch={@url}
      data-scroll="top"
      class="inline-flex gap-1 items-center justify-center text-sm font-medium transition-colors rounded-full py-1.5 px-4 bg-rose-500/10 text-rose-400 ring-1 ring-inset ring-rose-500/20 hover:text-rose-300 hover:ring-rose-300"
    >
      <%= if @icon_name && @icon_position == :left do %>
        <MusicListingsWeb.CoreComponents.icon name={@icon_name} class="size-3" />
      <% end %>
      {@label}
      <%= if @icon_name && @icon_position == :right do %>
        <MusicListingsWeb.CoreComponents.icon name={@icon_name} class="size-3" />
      <% end %>
    </.link>
    """
  end

  @doc """
  Renders a loading indicator

  ## Example

  <.loading_indicator />
  """
  def loading_indicator(assigns) do
    ~H"""
    <div class="flex justify-center mt-36 text-rose-400">
      <MusicListingsWeb.CoreComponents.icon name="hero-cog-6-tooth" class="animate-spin size-24" />
    </div>
    """
  end

  @doc """
  Renders a pager control

  ## Example

  <.pager
    current_page={@current_page}
    total_pages={@total_pages}
    path={~p"/events/venue"}
  />
  """

  attr :current_page, :integer, required: true
  attr :total_pages, :integer, required: true
  attr :path, :string, required: true

  def pager(assigns) do
    ~H"""
    <div class="flex items-center gap-3">
      <%= if @current_page > 1 do %>
        <.button_link
          label="Prev page"
          url={@path <> "?page=#{@current_page - 1}"}
          icon_name="hero-arrow-left"
          icon_position={:left}
        />
      <% end %>
      <%= if @current_page < @total_pages do %>
        <.button_link
          label="Next page"
          url={@path <> "?page=#{@current_page + 1}"}
          icon_name="hero-arrow-right"
        />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the date filter

  ## Example

  <.date_filter for={@form} selected_date={@selected_date} />
  """

  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :selected_date, :string, default: nil

  def date_filter(assigns) do
    ~H"""
    <div id="date-filter-component" phx-hook="DateFilter">
      <button
        phx-click={toggle_date_filtering()}
        type="button"
        class="flex items-center justify-between gap-2 px-4 py-2.5 bg-neutral-900 border border-neutral-700 rounded-lg text-sm text-neutral-300 hover:border-neutral-600 transition-colors"
      >
        <MusicListingsWeb.CoreComponents.icon name="hero-calendar" class="size-4 text-neutral-500" />
        <span>
          <%= if @selected_date && !today?(@selected_date) do %>
            {format_filter_date(@selected_date)}
          <% else %>
            Jump to date
          <% end %>
        </span>
        <span id="date-filter-chevron" class="inline-block transition duration-200">
          <MusicListingsWeb.CoreComponents.icon
            name="hero-chevron-down"
            class="size-4 text-neutral-500"
          />
        </span>
      </button>

      <.form
        for={@for}
        id="date-filter-form"
        class="hidden"
        phx-submit={JS.push("date-filter-changed") |> toggle_date_filtering()}
      >
        <div class="relative" phx-click-away={toggle_date_filtering()}>
          <div class="absolute z-10 mt-2 rounded-xl bg-neutral-900 py-4 px-4 shadow-2xl shadow-black/50 border border-neutral-700">
            <div class="flex flex-col gap-3">
              <label for="filter_date" class="text-sm font-medium text-neutral-300">
                Select date:
              </label>
              <input
                type="date"
                id="filter_date"
                name="date"
                value={@selected_date}
                class="rounded-lg border-neutral-700 bg-neutral-800 text-neutral-50 text-sm focus:border-rose-400 focus:ring-rose-400"
              />
              <button
                type="submit"
                class="w-full text-sm font-medium text-neutral-950 bg-rose-500 hover:bg-rose-400 rounded-lg px-3 py-1.5 transition-colors"
              >
                Go
              </button>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  defp toggle_date_filtering(js \\ %JS{}) do
    js
    |> JS.toggle(
      to: "#date-filter-form",
      in: {"transition ease-in-out duration-200", "opacity-0", "opacity-100"},
      out: {"transition ease-in-out duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.toggle_class("rotate-180", to: "#date-filter-chevron")
  end

  @doc """
  Renders the date filter status

  ## Example

  <.date_filter_status selected_date={@selected_date} />
  """
  attr :selected_date, :string, default: nil

  def date_filter_status(assigns) do
    ~H"""
    <%= if @selected_date && !today?(@selected_date) do %>
      <div class="flex items-center gap-2 text-sm text-neutral-400 -mt-2 mb-4">
        <span>Showing events from {format_filter_date(@selected_date)} onwards.</span>
        <a
          id="clear-date-filter"
          href="#"
          phx-click="clear-date-filter"
          class="text-rose-400 hover:text-rose-300 underline underline-offset-2"
        >
          Clear
        </a>
      </div>
    <% end %>
    """
  end

  defp today?(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Date.compare(date, Date.utc_today()) == :eq
      _error -> false
    end
  end

  defp today?(_other), do: false

  defp format_filter_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> DateHelpers.format_date(date)
      _error -> date_string
    end
  end

  defp format_filter_date(_other), do: ""

  @doc """
  Renders the venue filter

  ## Example

  <.venue_filter for={@form} venues={@venues} venue_ids={@venue_ids} />
  """

  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :venues, :list, required: true
  attr :venue_ids, :list, required: true

  def venue_filter(assigns) do
    ~H"""
    <div id="venue-filter-component" phx-hook="VenueFilter">
      <button
        phx-click={toggle_venue_filtering()}
        type="button"
        class="flex items-center justify-between gap-2 min-w-48 px-4 py-2.5 bg-neutral-900 border border-neutral-700 rounded-lg text-sm text-neutral-300 hover:border-neutral-600 transition-colors"
      >
        <MusicListingsWeb.CoreComponents.icon
          name="hero-building-storefront"
          class="size-4 text-neutral-500"
        />
        <span>
          <%= if @venue_ids == [] do %>
            All venues
          <% else %>
            {Enum.count(@venue_ids)} venue(s)
          <% end %>
        </span>
        <span id="venue-filter-chevron" class="inline-block transition duration-200">
          <MusicListingsWeb.CoreComponents.icon
            name="hero-chevron-down"
            class="size-4 text-neutral-500"
          />
        </span>
      </button>

      <.form for={@for} as={:for} id="venue-filters" class="hidden" phx-change="venue-filter-selected">
        <div class="relative" phx-click-away={toggle_venue_filtering()}>
          <ul
            class="absolute z-20 mt-2 max-h-72 w-80 overflow-auto rounded-xl bg-neutral-900 py-2 text-sm shadow-2xl shadow-black/50 border border-neutral-700"
            tabindex="-1"
          >
            <%= for venue <- @venues do %>
              <li
                class="relative cursor-pointer select-none py-2 pl-10 pr-4 text-neutral-200 hover:bg-neutral-800 transition-colors"
                role="option"
              >
                <label for={"#{venue.id}"} class="block truncate cursor-pointer">
                  {venue.name}
                </label>
                <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                  <input
                    id={"#{venue.id}"}
                    name={venue.id}
                    value="true"
                    type="checkbox"
                    checked={Integer.to_string(venue.id) in @venue_ids}
                    class="rounded border-neutral-600 bg-neutral-800 text-rose-500 focus:ring-0 focus:ring-offset-0 cursor-pointer"
                  />
                </span>
              </li>
            <% end %>
          </ul>
        </div>
      </.form>
    </div>
    """
  end

  defp toggle_venue_filtering(js \\ %JS{}) do
    js
    |> JS.toggle(
      to: "#venue-filters",
      in: {"transition ease-in-out duration-200", "opacity-0", "opacity-100"},
      out: {"transition ease-in-out duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.toggle_class("rotate-180", to: "#venue-filter-chevron")
  end

  @doc """
  Renders the vender filter status

  ## Example

  <.venue_filter_status venue_ids={@venue_ids} />
  """
  attr :venue_ids, :list, required: true

  def venue_filter_status(assigns) do
    ~H"""
    <%= if @venue_ids != [] do %>
      <div class="flex items-center gap-2 text-sm text-neutral-400 -mt-2 mb-4">
        <span>Filtering by {Enum.count(@venue_ids)} venue(s).</span>
        <a
          href="#"
          phx-click="clear-venue-filtering"
          class="text-rose-400 hover:text-rose-300 underline underline-offset-2"
        >
          Clear
        </a>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders information about a venue

  ## Example

  <.venue_card venue={@venue} />
  """
  def venue_card(assigns) do
    ~H"""
    <div class="bg-neutral-900 rounded-2xl p-6 sm:p-8 border border-neutral-800">
      <div class="flex flex-col lg:flex-row lg:items-start gap-6">
        <div class="flex-1">
          <h1 class="font-display text-3xl sm:text-4xl font-bold text-neutral-50">
            {@venue.name}
          </h1>
          <div class="mt-3 space-y-0.5 text-sm text-neutral-400">
            <p>{@venue.street}</p>
            <p>{"#{@venue.city} #{@venue.province}"}</p>
            <p>{"#{@venue.country} #{@venue.postal_code}"}</p>
          </div>
          <a
            href={@venue.website}
            class="inline-flex items-center gap-1.5 mt-4 text-sm font-medium text-rose-400 hover:text-rose-300 transition-colors"
            target="_blank"
          >
            <MusicListingsWeb.CoreComponents.icon
              name="hero-arrow-top-right-on-square"
              class="size-4"
            /> Visit website
          </a>
        </div>

        <div class="w-full lg:w-80 h-48 rounded-xl overflow-hidden border border-neutral-800">
          <iframe
            id={"venue-map-#{@venue.id}"}
            class="w-full h-full"
            src={@venue.google_map_url}
            frameborder="0"
            style="border:0;"
            allowfullscreen=""
            aria-hidden="false"
            tabindex="0"
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
            sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"
            phx-update="ignore"
          >
          </iframe>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a grid of venue summary cards

  ## Example

  <.venue_summary venues={@venues} />
  """
  attr :venues, :list, required: true

  def venue_summary(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-8">
      <%= for venue <- @venues do %>
        <a
          href={~p"/events/venue/#{venue.id}"}
          id={"venue-#{venue.id}"}
          class="block bg-neutral-900 rounded-xl p-5 border border-neutral-800 hover:border-rose-500/50 hover:bg-neutral-900/80 transition-all duration-200 group"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0 flex-1">
              <h3 class="text-base font-semibold text-neutral-50 group-hover:text-rose-400 transition-colors truncate">
                {venue.name}
              </h3>
              <p class="text-sm text-neutral-500 mt-1 truncate">{venue.street}</p>
            </div>
            <span class="flex-shrink-0 text-xs font-medium text-rose-400 bg-rose-500/10 px-3 py-1 rounded-full">
              {venue.upcoming_event_count} Upcoming Events
            </span>
          </div>
        </a>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a list of events for the passed in events

  ## Example

  <.events_list events={@events} current_user={current_user} />
  """
  attr :events, :list, required: true
  attr :current_user, :any, required: true

  def events_list(assigns) do
    ~H"""
    <div>
      <%= for {date, events} <- @events do %>
        <.events_date_header date={date} />
        <div class="space-y-3 mb-12">
          <%= for event <- events do %>
            <.event_card event={event} current_user={@current_user} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :submitted_events, :list, required: true

  def submitted_events(assigns) do
    ~H"""
    <table class="min-w-full divide-y divide-neutral-700">
      <thead>
        <tr>
          <.submitted_event_column_header label="Title / URL" first_col={true} />
          <.submitted_event_column_header label="Venue" />
          <.submitted_event_column_header label="Date" />
          <.submitted_event_column_header label="Time" />
          <.submitted_event_column_header label="Price" />
          <.submitted_event_column_header label="Status" sr_only={true} />
        </tr>
      </thead>
      <tbody class="divide-y divide-neutral-800">
        <%= for submitted_event <- @submitted_events do %>
          <tr id={"event-#{submitted_event.id}"}>
            <.submitted_event_title title={submitted_event.title} url={submitted_event.url} />
            <.submitted_event_column_value value={submitted_event.venue} />
            <.submitted_event_column_value value={submitted_event.date} />
            <.submitted_event_column_value value={
              format_submitted_event_optional_field(submitted_event.time)
            } />
            <.submitted_event_column_value value={
              format_submitted_event_optional_field(submitted_event.price)
            } />
            <.submitted_event_approval_status submitted_event={submitted_event} />
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp submitted_event_title(assigns) do
    ~H"""
    <td class="py-5 pl-4 pr-3 text-sm sm:pl-0 text-neutral-50 w-1/2">
      <div class="flex items-center">
        <div class="break-words">
          <div class="font-medium">{@title}</div>
          <a
            href={@url}
            target="_blank"
            class="mt-1 text-rose-400 hover:text-rose-300 break-all"
          >
            {@url}
          </a>
        </div>
      </div>
    </td>
    """
  end

  defp submitted_event_column_value(assigns) do
    ~H"""
    <td class="whitespace-nowrap px-2 py-4 text-sm text-neutral-400">
      {@value}
    </td>
    """
  end

  defp submitted_event_approval_status(assigns) do
    ~H"""
    <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
      <span :if={@submitted_event.approved?} class="text-amber-400">Approved</span>
      <button
        :if={!@submitted_event.approved?}
        phx-click="approve-submitted-event"
        phx-value-id={@submitted_event.id}
        data-confirm="Are you sure?"
        class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition-colors rounded-full py-1 px-3 bg-rose-500/10 text-rose-400 ring-1 ring-inset ring-rose-500/20 hover:text-rose-300 hover:ring-rose-300"
      >
        Approve
      </button>
    </td>
    """
  end

  defp submitted_event_column_header(assigns) do
    th_class =
      if assigns[:first_col],
        do: "py-3.5 pl-4 pr-3 text-left text-md font-semibold text-neutral-50 sm:pl-0 w-1/2",
        else: "px-2 py-3.5 text-left text-md font-semibold text-neutral-50"

    span_class = if assigns[:sr_only], do: "sr-only", else: ""

    assigns = assign(assigns, th_class: th_class, span_class: span_class)

    ~H"""
    <th scope="col" class={@th_class}>
      <span class={@span_class}>{@label}</span>
    </th>
    """
  end

  defp format_submitted_event_optional_field(nil), do: "- - -"
  defp format_submitted_event_optional_field(string), do: string

  @doc """
  Renders a list of events for the passed in events, specific to a single venue

  ## Example

  <.venue_events_list events={@events} current_user={@current_user} />
  """
  attr :events, :list, required: true
  attr :current_user, :any, required: true

  def venue_events_list(assigns) do
    ~H"""
    <div class="space-y-3">
      <%= for event <- @events do %>
        <div class="bg-neutral-900 rounded-xl p-4 sm:p-5 border border-neutral-800 hover:border-neutral-700 transition-all duration-200">
          <div class="flex items-start justify-between gap-4">
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2 mb-1">
                <.event_date date={event.date} />
                <.event_age_restriction age_restriction={event.age_restriction} />
              </div>
              <h3 class="text-base sm:text-lg font-semibold text-neutral-50 leading-snug">
                {event.title}
                <%= if event.openers != [] do %>
                  <span class="font-normal text-neutral-400">
                    with {Enum.join(event.openers, ", ")}
                  </span>
                <% end %>
              </h3>
            </div>
          </div>
          <%= for showtime <- event.showtimes do %>
            <div
              id={"event-#{showtime.event_id}"}
              class="mt-3 flex flex-wrap items-center gap-2"
            >
              <.event_time time={showtime.time} />
              <.event_ticket_url
                ticket_url={showtime.ticket_url}
                price_format={event.price_format}
                price_lo={event.price_lo}
                price_hi={event.price_hi}
              />
              <.event_details_url details_url={showtime.details_url} />
              <.delete_event_link current_user={@current_user} event_id={showtime.event_id} />
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp events_date_header(assigns) do
    ~H"""
    <div
      id={"date-#{@date}"}
      class="flex items-center gap-4 pt-10 pb-4 first:pt-0 scroll-mt-20"
    >
      <h2 class="font-display text-2xl sm:text-3xl font-bold text-neutral-50 whitespace-nowrap">
        <time datetime={@date}>{DateHelpers.format_date(@date)}</time>
      </h2>
      <div class="flex-1 h-px bg-neutral-800"></div>
    </div>
    """
  end

  defp event_card(assigns) do
    ~H"""
    <div class="bg-neutral-900 rounded-xl p-4 sm:p-5 border border-neutral-800 hover:border-neutral-700 transition-all duration-200">
      <div class="flex items-start justify-between gap-4">
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2 mb-1">
            <.event_venue venue={@event.venue} />
            <.event_age_restriction age_restriction={@event.age_restriction} />
          </div>
          <h3 class="text-base sm:text-lg font-semibold text-neutral-50 leading-snug">
            {@event.title}
            <%= if @event.openers != [] do %>
              <span class="font-normal text-neutral-400">
                with {@event.openers |> Enum.join(", ")}
              </span>
            <% end %>
          </h3>
        </div>
      </div>
      <%= for showtime <- @event.showtimes do %>
        <div
          id={"event-#{showtime.event_id}"}
          class="mt-3 flex flex-wrap items-center gap-2"
        >
          <.event_time time={showtime.time} />
          <.event_ticket_url
            ticket_url={showtime.ticket_url}
            price_format={@event.price_format}
            price_lo={@event.price_lo}
            price_hi={@event.price_hi}
          />
          <.event_details_url details_url={showtime.details_url} />
          <.delete_event_link current_user={@current_user} event_id={showtime.event_id} />
        </div>
      <% end %>
    </div>
    """
  end

  defp event_date(assigns) do
    ~H"""
    <span class="text-xs font-medium text-neutral-500 [font-variant-numeric:tabular-nums]">
      {DateHelpers.format_date(@date)}
    </span>
    """
  end

  defp event_venue(assigns) do
    ~H"""
    <a
      href={~p"/events/venue/#{@venue.id}"}
      class="text-xs font-semibold uppercase tracking-wider text-rose-400 hover:text-rose-300 transition-colors"
    >
      {@venue.name}
    </a>
    """
  end

  defp event_age_restriction(%{age_restriction: :unknown} = assigns), do: ~H""

  defp event_age_restriction(assigns) do
    ~H"""
    <span class="bg-amber-400/10 text-amber-400 text-xs font-medium px-2 py-0.5 rounded-full">
      {format_age_restriction(@age_restriction)}
    </span>
    """
  end

  defp format_age_restriction(:all_ages), do: "All Ages"
  defp format_age_restriction(:eighteen_plus), do: "18+"
  defp format_age_restriction(:nineteen_plus), do: "19+"

  defp event_time(%{time: nil} = assigns), do: ~H""

  defp event_time(assigns) do
    ~H"""
    <time class="text-xs text-neutral-500 font-sans [font-variant-numeric:tabular-nums]">
      {DateHelpers.format_time(@time)}
    </time>
    """
  end

  defp event_ticket_url(assigns) do
    ~H"""
    <%= if @ticket_url do %>
      <a
        href={@ticket_url}
        class="inline-flex items-center gap-1 text-xs font-medium text-rose-400 hover:text-rose-300 bg-rose-500/10 px-3 py-1 rounded-full transition-colors"
        target="_blank"
      >
        <MusicListingsWeb.CoreComponents.icon
          name="hero-ticket-solid"
          class="size-3.5"
        /> Tickets
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </a>
    <% end %>
    <%= if @price_format != :unknown && !@ticket_url do %>
      <span class="inline-flex items-center text-xs font-medium text-rose-400 bg-rose-500/10 px-3 py-1 rounded-full">
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </span>
    <% end %>
    """
  end

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    ~H"""
    <a
      href={@details_url}
      class="inline-flex items-center gap-1 text-xs font-medium text-neutral-400 hover:text-neutral-300 bg-neutral-800 px-3 py-1 rounded-full transition-colors"
      target="_blank"
    >
      <MusicListingsWeb.CoreComponents.icon
        name="hero-information-circle-solid"
        class="size-3.5"
      /> Details
    </a>
    """
  end

  defp event_price(%{price_format: :unknown} = assigns), do: ~H""

  defp event_price(%{price_format: :free} = assigns) do
    ~H"""
    FREE
    """
  end

  defp event_price(%{price_format: :pwyc} = assigns) do
    ~H"""
    PWYC
    """
  end

  defp event_price(%{price_format: :fixed} = assigns) do
    ~H"""
    ${@price_lo}
    """
  end

  defp event_price(%{price_format: :range} = assigns) do
    ~H"""
    ${@price_lo} - ${@price_hi}
    """
  end

  defp event_price(%{price_format: :variable} = assigns) do
    ~H"""
    ${@price_lo}+
    """
  end

  defp delete_event_link(assigns) do
    ~H"""
    <.when_admin current_user={@current_user}>
      <button
        phx-click="delete-event"
        phx-value-id={@event_id}
        data-confirm="Are you sure?"
        class="text-xs text-neutral-500 hover:text-red-400 transition-colors"
      >
        Delete
      </button>
    </.when_admin>
    """
  end
end
