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
  alias MusicListingsWeb.SEO
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
    <div class="mb-8 border-b border-hairline pb-6">
      <p class="kicker flex items-center gap-2">
        <span class="inline-block h-2 w-8 bg-spotlight"></span> Toronto Music Listings
      </p>
      <h1 class="headline mt-4 text-5xl text-paper sm:text-6xl">
        {@header}
      </h1>
      <p :if={@description} class="mt-3 max-w-xl text-sm leading-relaxed text-paper-dim">
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
    <div class="relative px-6 pt-10 pb-8 lg:static lg:px-8 lg:py-32">
      <div class="mx-auto max-w-xl lg:mx-0 lg:max-w-lg">
        <p class="kicker flex items-center gap-2">
          <span class="inline-block h-2 w-8 bg-spotlight"></span> Got a show?
        </p>
        <h1 class="headline mt-4 text-6xl text-paper sm:text-7xl">
          {@header}
        </h1>
        <div class="mt-6 space-y-6 text-base leading-relaxed text-paper-dim lg:text-lg">
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
      class="inline-flex gap-1 items-center justify-center rounded-full py-1.5 px-4 font-mono text-xs uppercase tracking-wider transition-colors bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30 hover:bg-spotlight hover:text-ink"
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
    <div class="flex justify-center mt-36 text-spotlight">
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
        class="flex items-center justify-between gap-2 px-4 py-2.5 bg-ink-2 border border-hairline rounded-lg text-sm text-paper-dim hover:border-paper-dim transition-colors"
      >
        <MusicListingsWeb.CoreComponents.icon name="hero-calendar" class="size-4 text-paper-dim" />
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
            class="size-4 text-paper-dim"
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
          <div class="absolute z-10 mt-2 rounded-xl bg-ink-2 py-4 px-4 shadow-2xl shadow-black/50 border border-hairline">
            <div class="flex flex-col gap-3">
              <label for="filter_date" class="text-sm font-medium text-paper-dim">
                Select date:
              </label>
              <input
                type="date"
                id="filter_date"
                name="date"
                value={@selected_date}
                class="rounded-lg border-hairline bg-ink-3 text-paper text-sm focus:border-spotlight focus:ring-spotlight"
              />
              <button
                type="submit"
                class="w-full text-sm font-medium text-ink bg-spotlight hover:bg-spotlight-deep rounded-lg px-3 py-1.5 transition-colors"
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
      <div class="flex items-center gap-2 text-sm text-paper-dim -mt-2 mb-4">
        <span>Showing events from {format_filter_date(@selected_date)} onwards.</span>
        <a
          id="clear-date-filter"
          href="#"
          phx-click="clear-date-filter"
          class="text-spotlight hover:text-spotlight-deep underline underline-offset-2"
        >
          Clear
        </a>
      </div>
    <% end %>
    """
  end

  defp today?(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Date.compare(date, DateHelpers.effective_today_eastern()) == :eq
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
  Renders the sort toggle

  ## Example

  <.sort_toggle sort_by={@sort_by} />
  """

  attr :sort_by, :string, default: "title"

  def sort_toggle(assigns) do
    ~H"""
    <div id="sort-by-component" phx-hook="SortBy" class="flex items-center">
      <div class="inline-flex rounded-lg border border-hairline bg-ink-2 p-0.5">
        <button
          type="button"
          phx-click="sort-changed"
          phx-value-sort-by="title"
          class={[
            "px-3 py-1.5 text-sm rounded-md transition-colors",
            if(@sort_by == "title",
              do: "bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30",
              else: "text-paper-dim hover:text-paper"
            )
          ]}
        >
          By Title
        </button>
        <button
          type="button"
          phx-click="sort-changed"
          phx-value-sort-by="venue"
          class={[
            "px-3 py-1.5 text-sm rounded-md transition-colors",
            if(@sort_by == "venue",
              do: "bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30",
              else: "text-paper-dim hover:text-paper"
            )
          ]}
        >
          By Venue
        </button>
      </div>
    </div>
    """
  end

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
        class="flex items-center justify-between gap-2 min-w-48 px-4 py-2.5 bg-ink-2 border border-hairline rounded-lg text-sm text-paper-dim hover:border-paper-dim transition-colors"
      >
        <MusicListingsWeb.CoreComponents.icon
          name="hero-building-storefront"
          class="size-4 text-paper-dim"
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
            class="size-4 text-paper-dim"
          />
        </span>
      </button>

      <.form for={@for} as={:for} id="venue-filters" class="hidden" phx-change="venue-filter-selected">
        <div class="relative" phx-click-away={toggle_venue_filtering()}>
          <ul
            class="absolute z-20 mt-2 max-h-72 w-80 overflow-auto rounded-xl bg-ink-2 py-2 text-sm shadow-2xl shadow-black/50 border border-hairline"
            tabindex="-1"
          >
            <%= for venue <- @venues do %>
              <li
                class="relative cursor-pointer select-none py-2 pl-10 pr-4 text-paper hover:bg-ink-3 transition-colors"
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
                    class="rounded-sm border-hairline bg-ink-3 text-spotlight focus:ring-0 focus:ring-offset-0 cursor-pointer"
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
      <div class="flex items-center gap-2 text-sm text-paper-dim -mt-2 mb-4">
        <span>Filtering by {Enum.count(@venue_ids)} venue(s).</span>
        <a
          href="#"
          phx-click="clear-venue-filtering"
          class="text-spotlight hover:text-spotlight-deep underline underline-offset-2"
        >
          Clear
        </a>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders a bottom sheet overlay for mobile filter/sort controls.

  ## Example

  <.bottom_sheet id="mobile-filters">
    <p>Filter content here</p>
  </.bottom_sheet>
  """

  attr :id, :string, required: true
  slot :inner_block, required: true

  def bottom_sheet(assigns) do
    ~H"""
    <div id={@id} class="relative z-50 hidden md:hidden" phx-remove={hide_bottom_sheet(@id)}>
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-ink/80 transition-opacity"
        aria-hidden="true"
        phx-click={hide_bottom_sheet(@id)}
      />
      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0" aria-labelledby={"#{@id}-title"} role="dialog" aria-modal="true">
          <.focus_wrap
            id={"#{@id}-panel"}
            phx-window-keydown={hide_bottom_sheet(@id)}
            phx-key="escape"
            class="fixed inset-x-0 bottom-0 max-h-[85vh] overflow-y-auto rounded-t-2xl bg-ink-2 border-t border-hairline shadow-2xl shadow-black/50 transform transition-transform"
          >
            <div class="sticky top-0 bg-ink-2 z-10 px-5 pt-3 pb-4 border-b border-hairline">
              <div class="w-10 h-1 rounded-full bg-hairline mx-auto mb-4" />
              <div class="flex items-center justify-between">
                <h2 id={"#{@id}-title"} class="text-lg font-semibold text-paper">Filters</h2>
                <button
                  type="button"
                  phx-click={hide_bottom_sheet(@id)}
                  class="p-1.5 rounded-lg text-paper-dim hover:text-paper hover:bg-ink-3 transition-colors"
                  aria-label="Close filters"
                >
                  <MusicListingsWeb.CoreComponents.icon name="hero-x-mark" class="size-5" />
                </button>
              </div>
            </div>
            <div class="px-5 py-5 space-y-6">
              {render_slot(@inner_block)}
            </div>
          </.focus_wrap>
        </div>
      </div>
    </div>
    """
  end

  def show_bottom_sheet(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-backdrop",
      time: 300,
      transition: {"transition-all ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-panel",
      time: 300,
      transition: {"transition-all ease-out duration-300", "translate-y-full", "translate-y-0"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-panel")
  end

  defp hide_bottom_sheet(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
      transition: {"transition-all ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-panel",
      transition: {"transition-all ease-in duration-200", "translate-y-0", "translate-y-full"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders the mobile filter button that opens the bottom sheet.

  ## Example

  <.mobile_filter_button />
  """

  def mobile_filter_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click={show_bottom_sheet("mobile-filters")}
      class="inline-flex items-center gap-2 px-4 py-2.5 bg-ink-2 border border-hairline rounded-lg text-sm text-paper-dim hover:border-paper-dim transition-colors"
    >
      <MusicListingsWeb.CoreComponents.icon
        name="hero-adjustments-horizontal"
        class="size-4 text-paper-dim"
      />
      <span>Filters</span>
    </button>
    """
  end

  @doc """
  Renders dismissible chips showing active filter state on mobile.

  ## Example

  <.mobile_filter_chips venue_ids={@venue_ids} selected_date={@selected_date} />
  """

  attr :venue_ids, :list, required: true
  attr :selected_date, :string, default: nil

  def mobile_filter_chips(assigns) do
    has_date_filter =
      assigns.selected_date != nil && assigns.selected_date != "" &&
        !today?(assigns.selected_date)

    assigns = assign(assigns, :has_date_filter, has_date_filter)

    ~H"""
    <div
      :if={@venue_ids != [] || @has_date_filter}
      class="flex flex-wrap justify-end gap-2"
    >
      <span
        :if={@venue_ids != []}
        class="inline-flex items-center gap-1 text-xs font-medium bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30 px-2.5 py-1 rounded-full"
      >
        {Enum.count(@venue_ids)} venue(s)
        <button type="button" phx-click="clear-venue-filtering" class="hover:text-spotlight-deep">
          <MusicListingsWeb.CoreComponents.icon name="hero-x-mark" class="size-3" />
        </button>
      </span>
      <span
        :if={@has_date_filter}
        class="inline-flex items-center gap-1 text-xs font-medium bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30 px-2.5 py-1 rounded-full"
      >
        From {format_filter_date(@selected_date)}
        <button type="button" phx-click="clear-date-filter" class="hover:text-spotlight-deep">
          <MusicListingsWeb.CoreComponents.icon name="hero-x-mark" class="size-3" />
        </button>
      </span>
    </div>
    """
  end

  @doc """
  Renders the venue filter inline (not dropdown) for the mobile bottom sheet.

  ## Example

  <.mobile_venue_filter for={@form} venues={@venues} venue_ids={@venue_ids} />
  """

  attr :for, :any, required: true
  attr :venues, :list, required: true
  attr :venue_ids, :list, required: true

  def mobile_venue_filter(assigns) do
    ~H"""
    <div>
      <h3 class="kicker mb-3">Venues</h3>
      <.form for={@for} as={:for} id="mobile-venue-filters" phx-change="venue-filter-selected">
        <ul class="max-h-60 overflow-y-auto space-y-1 -mx-1">
          <%= for venue <- @venues do %>
            <li class="relative cursor-pointer select-none py-2 pl-10 pr-4 text-paper hover:bg-ink-3 rounded-lg transition-colors">
              <label for={"mobile-#{venue.id}"} class="block truncate cursor-pointer text-sm">
                {venue.name}
              </label>
              <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                <input
                  id={"mobile-#{venue.id}"}
                  name={venue.id}
                  value="true"
                  type="checkbox"
                  checked={Integer.to_string(venue.id) in @venue_ids}
                  class="rounded-sm border-hairline bg-ink-3 text-spotlight focus:ring-0 focus:ring-offset-0 cursor-pointer"
                />
              </span>
            </li>
          <% end %>
        </ul>
      </.form>
    </div>
    """
  end

  @doc """
  Renders the date filter inline for the mobile bottom sheet.

  ## Example

  <.mobile_date_filter for={@form} selected_date={@selected_date} />
  """

  attr :for, :any, required: true
  attr :selected_date, :string, default: nil

  def mobile_date_filter(assigns) do
    ~H"""
    <div>
      <h3 class="kicker mb-3">Date</h3>
      <.form
        for={@for}
        id="mobile-date-filter-form"
        phx-submit={JS.push("date-filter-changed") |> hide_bottom_sheet("mobile-filters")}
      >
        <div class="flex items-center gap-3">
          <input
            type="date"
            id="mobile-filter-date"
            name="date"
            value={@selected_date}
            class="flex-1 rounded-lg border-hairline bg-ink-3 text-paper text-sm focus:border-spotlight focus:ring-spotlight"
          />
          <button
            type="submit"
            class="text-sm font-medium text-ink bg-spotlight hover:bg-spotlight-deep rounded-lg px-4 py-2 transition-colors"
          >
            Go
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @doc """
  Renders the sort toggle for the mobile bottom sheet.

  ## Example

  <.mobile_sort_toggle sort_by={@sort_by} />
  """

  attr :sort_by, :string, default: "title"

  def mobile_sort_toggle(assigns) do
    ~H"""
    <div>
      <h3 class="kicker mb-3">Sort by</h3>
      <div class="inline-flex rounded-lg border border-hairline bg-ink-3 p-0.5">
        <button
          type="button"
          phx-click="sort-changed"
          phx-value-sort-by="title"
          class={[
            "px-4 py-2 text-sm rounded-md transition-colors",
            if(@sort_by == "title",
              do: "bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30",
              else: "text-paper-dim hover:text-paper"
            )
          ]}
        >
          By Title
        </button>
        <button
          type="button"
          phx-click="sort-changed"
          phx-value-sort-by="venue"
          class={[
            "px-4 py-2 text-sm rounded-md transition-colors",
            if(@sort_by == "venue",
              do: "bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30",
              else: "text-paper-dim hover:text-paper"
            )
          ]}
        >
          By Venue
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders information about a venue

  ## Example

  <.venue_card venue={@venue} />
  """
  def venue_card(assigns) do
    ~H"""
    <div class="border-b border-hairline pb-8">
      <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
        <div class="flex-1">
          <p class="kicker flex items-center gap-2">
            <span class="inline-block h-2 w-8 bg-spotlight"></span> Venue
          </p>
          <h1 class="headline mt-3 text-5xl text-paper sm:text-6xl lg:text-7xl">
            {@venue.name}
          </h1>
          <div class="mt-4 space-y-0.5 font-mono text-sm text-paper-dim">
            <p>{@venue.street}</p>
            <p>{"#{@venue.city} #{@venue.province} · #{@venue.country} #{@venue.postal_code}"}</p>
          </div>
          <a
            href={@venue.website}
            target="_blank"
            rel="noopener"
            class="mt-4 inline-flex items-center gap-1.5 font-mono text-xs uppercase tracking-wider text-spotlight transition-colors hover:text-spotlight-deep"
          >
            <MusicListingsWeb.CoreComponents.icon
              name="hero-arrow-top-right-on-square"
              class="size-4"
            /> Visit website
          </a>
        </div>

        <div class="h-48 w-full overflow-hidden border border-hairline grayscale transition-all duration-300 hover:grayscale-0 lg:w-96">
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
          ></iframe>
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
    <div class="mt-8 grid grid-cols-1 border-t border-hairline sm:grid-cols-2">
      <%= for venue <- @venues do %>
        <a
          href={~p"/events/venue/#{venue.id}"}
          id={"venue-#{venue.id}"}
          class="group flex items-center justify-between gap-4 border-b border-hairline py-5 transition-colors hover:bg-ink-2/60 sm:px-5 sm:[&:nth-child(odd)]:border-r"
        >
          <div class="min-w-0 flex-1">
            <h3 class="font-display text-2xl font-bold leading-none text-paper transition-colors group-hover:text-spotlight">
              {venue.name}
            </h3>
            <p class="kicker mt-1.5">{venue.street}</p>
          </div>
          <span class="shrink-0 bg-spotlight/10 text-spotlight px-3 py-1 font-mono text-xs tabular-nums uppercase tracking-wider">
            {venue.upcoming_event_count} Upcoming Events
          </span>
        </a>
      <% end %>
    </div>
    """
  end

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
              <.venue_grouped_card venue={venue} events={venue_events} current_user={@current_user} />
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
      {first_time || ~T[23:59:59], event.title}
    end)
  end

  attr :submitted_events, :list, required: true

  def submitted_events(assigns) do
    ~H"""
    <table class="min-w-full divide-y divide-hairline">
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
      <tbody class="divide-y divide-hairline">
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
    <td class="py-5 pl-4 pr-3 text-sm sm:pl-0 text-paper w-1/2">
      <div class="flex items-center">
        <div class="break-words">
          <div class="font-medium">{@title}</div>
          <a
            href={@url}
            target="_blank"
            rel="noopener"
            class="mt-1 text-spotlight hover:text-spotlight-deep break-all"
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
    <td class="whitespace-nowrap px-2 py-4 text-sm text-paper-dim">
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
        class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition-colors rounded-full py-1 px-3 bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30 hover:bg-spotlight hover:text-ink"
      >
        Approve
      </button>
    </td>
    """
  end

  defp submitted_event_column_header(assigns) do
    th_class =
      if assigns[:first_col],
        do: "py-3.5 pl-4 pr-3 text-left text-md font-semibold text-paper sm:pl-0 w-1/2",
        else: "px-2 py-3.5 text-left text-md font-semibold text-paper"

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

  @doc """
  Renders a notice banner for events that are no longer current (past,
  cancelled, or otherwise removed from listings).

  ## Example

  <.event_notice message="This event has already taken place." />
  """
  attr :message, :string, required: true

  def event_notice(assigns) do
    ~H"""
    <div
      role="status"
      class="mb-6 rounded border border-amber-400/50 bg-amber-400/10 px-4 py-3 font-mono text-sm text-amber-300"
    >
      {@message}
    </div>
    """
  end

  @doc """
  Renders the breadcrumb navigation for an event show page.

  ## Example

  <.event_breadcrumb event={@event} />
  """
  attr :event, :any, required: true

  def event_breadcrumb(assigns) do
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

  @doc """
  Renders the event show page header: venue badge, title, and openers line.

  ## Example

  <.event_header event={@event} />
  """
  attr :event, :any, required: true

  def event_header(assigns) do
    ~H"""
    <p :if={@event.venue} class="kicker text-spotlight-deep">
      <.link navigate={~p"/events/venue/#{@event.venue.id}"} class="hover:text-spotlight">
        {@event.venue.name}
      </.link>
    </p>

    <h1 class="mt-3 font-display text-5xl font-bold leading-[0.9] text-paper sm:text-6xl lg:text-7xl">
      {@event.title}
    </h1>
    <p :if={@event.openers != []} class="mt-3 font-display text-2xl font-medium text-paper-dim">
      with {Enum.join(@event.openers, ", ")}
    </p>
    """
  end

  @doc """
  Renders the event metadata definition list (date, showtime, venue, age, price).

  ## Example

  <.event_details_list event={@event} />
  """
  attr :event, :any, required: true

  def event_details_list(assigns) do
    ~H"""
    <dl class="mt-8 grid grid-cols-2 border-t border-hairline sm:grid-cols-4">
      <div class="border-b border-hairline py-4 pr-4 sm:[&:not(:nth-child(4n))]:border-r sm:[&:not(:nth-child(4n+1))]:pl-4">
        <dt class="kicker">Date</dt>
        <dd class="mt-1.5 font-display text-xl font-bold text-paper">
          <time datetime={Date.to_iso8601(@event.date)}>
            {DateHelpers.format_date(@event.date)}
          </time>
        </dd>
      </div>
      <div
        :if={@event.time}
        class="border-b border-hairline py-4 pr-4 sm:[&:not(:nth-child(4n))]:border-r sm:[&:not(:nth-child(4n+1))]:pl-4"
      >
        <dt class="kicker">Showtime</dt>
        <dd class="mt-1.5 font-mono text-lg text-paper">{DateHelpers.format_time(@event.time)}</dd>
      </div>
      <div
        :if={@event.price_format != :unknown}
        class="border-b border-hairline py-4 pr-4 sm:[&:not(:nth-child(4n))]:border-r sm:[&:not(:nth-child(4n+1))]:pl-4"
      >
        <dt class="kicker">Price</dt>
        <dd class="mt-1.5 font-mono text-lg text-spotlight">{format_price(@event, :long)}</dd>
      </div>
      <div
        :if={@event.age_restriction != :unknown}
        class="border-b border-hairline py-4 pr-4 sm:[&:not(:nth-child(4n))]:border-r sm:[&:not(:nth-child(4n+1))]:pl-4"
      >
        <dt class="kicker">Age</dt>
        <dd class="mt-1.5 font-mono text-lg text-paper">
          {format_age_restriction(@event.age_restriction)}
        </dd>
      </div>
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

  @doc """
  Renders the ticket + details action buttons for an event show page.

  ## Example

  <.event_actions event={@event} />
  """
  attr :event, :any, required: true

  def event_actions(assigns) do
    ~H"""
    <div class="mt-8 flex flex-wrap items-center gap-3">
      <a
        :if={@event.ticket_url}
        href={MusicListings.Affiliate.maybe_wrap_affiliate_link(@event.ticket_url)}
        class="inline-flex h-9 items-center justify-center gap-x-2 rounded bg-spotlight px-4 font-mono text-xs font-medium uppercase tracking-widest text-ink transition-colors hover:bg-spotlight-deep"
        target="_blank"
        rel="noopener sponsored"
      >
        <MusicListingsWeb.CoreComponents.icon name="hero-ticket-solid" class="size-4" /> Get Tickets
      </a>
      <a
        :if={@event.details_url}
        href={@event.details_url}
        class="inline-flex h-9 items-center justify-center gap-x-2 rounded border border-hairline bg-ink px-4 font-mono text-xs font-medium uppercase tracking-widest text-paper transition-colors hover:bg-ink-3"
        target="_blank"
        rel="noopener"
      >
        <MusicListingsWeb.CoreComponents.icon
          name="hero-information-circle-solid"
          class="size-4"
        /> Venue page
      </a>
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

  defp event_card(assigns) do
    ~H"""
    <article class="group border-b border-hairline transition-colors duration-200 hover:bg-ink-2/60">
      <div class="grid grid-cols-1 gap-x-8 gap-y-3 px-1 py-6 sm:grid-cols-[1fr_auto] sm:items-start sm:px-3">
        <div class="min-w-0">
          <div class="mb-2 flex flex-wrap items-center gap-2.5">
            <.event_venue venue={@event.venue} />
            <.event_age_restriction age_restriction={@event.age_restriction} />
          </div>
          <h3 class="font-display text-2xl font-bold leading-[0.95] text-paper transition-colors group-hover:text-spotlight sm:text-3xl">
            <.event_title_link event_info={@event}>
              {@event.title}
            </.event_title_link>
          </h3>
          <p :if={@event.openers != []} class="mt-1.5 font-display text-lg font-medium text-paper-dim">
            with {@event.openers |> Enum.join(", ")}
          </p>
        </div>
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
              <.event_details_url details_url={showtime.details_url} />
              <.delete_event_link current_user={@current_user} event_id={showtime.event_id} />
            </div>
          <% end %>
        </div>
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
            <.event_details_url details_url={showtime.details_url} />
            <.delete_event_link current_user={@current_user} event_id={showtime.event_id} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :event_info, :any, required: true
  slot :inner_block, required: true

  defp event_title_link(assigns) do
    first_show = List.first(assigns.event_info.showtimes)
    slug = SEO.slugify(assigns.event_info.title || "event")
    assigns = assign(assigns, event_id: first_show && first_show.event_id, slug: slug)

    ~H"""
    <.link :if={@event_id} navigate={~p"/events/#{@event_id}/#{@slug}"} class="transition-colors">
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

  defp format_age_restriction(:all_ages), do: "All Ages"
  defp format_age_restriction(:eighteen_plus), do: "18+"
  defp format_age_restriction(:nineteen_plus), do: "19+"

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
        <MusicListingsWeb.CoreComponents.icon
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

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    ~H"""
    <a
      href={@details_url}
      class="inline-flex items-center gap-1 font-mono text-[0.7rem] uppercase tracking-wider text-paper-dim ring-1 ring-inset ring-hairline px-3 py-1 transition-colors hover:text-paper hover:ring-paper-dim"
      target="_blank"
      rel="noopener"
    >
      <MusicListingsWeb.CoreComponents.icon
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

  defp format_price(%{price_format: :free}, :short), do: "FREE"
  defp format_price(%{price_format: :free}, :long), do: "Free"
  defp format_price(%{price_format: :pwyc}, :short), do: "PWYC"
  defp format_price(%{price_format: :pwyc}, :long), do: "Pay what you can"
  defp format_price(%{price_format: :fixed, price_lo: lo}, _style), do: "$#{lo}"
  defp format_price(%{price_format: :variable, price_lo: lo}, _style), do: "$#{lo}+"

  defp format_price(%{price_format: :range, price_lo: lo, price_hi: hi}, _style),
    do: "$#{lo} – $#{hi}"

  defp format_price(_event, _style), do: ""

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
