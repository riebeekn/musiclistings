defmodule MusicListingsWeb.FilterComponents do
  @moduledoc """
  The events page's search and its desktop and mobile filters.
  """

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MusicListingsWeb.Endpoint,
    router: MusicListingsWeb.Router,
    statics: MusicListingsWeb.static_paths()

  import MusicListingsWeb.CoreComponents, only: [icon: 1]

  alias MusicListingsUtilities.DateHelpers
  alias Phoenix.LiveView.JS

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
        <.icon name="hero-calendar" class="size-4 text-paper-dim" />
        <span>
          <%= if @selected_date && !today?(@selected_date) do %>
            {format_filter_date(@selected_date)}
          <% else %>
            Jump to date
          <% end %>
        </span>
        <span id="date-filter-chevron" class="inline-block transition duration-200">
          <.icon
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
    <.filter_status
      :if={@selected_date && !today?(@selected_date)}
      id="clear-date-filter"
      on_clear="clear-date-filter"
    >
      Showing events from {format_filter_date(@selected_date)} onwards.
    </.filter_status>
    """
  end

  attr :id, :string, default: nil, doc: "the id of the clear link"
  attr :on_clear, :string, required: true, doc: "the event that clears the filter"
  slot :inner_block, required: true

  defp filter_status(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-sm text-paper-dim -mt-2 mb-4">
      <span>{render_slot(@inner_block)}</span>
      <a
        id={@id}
        href="#"
        phx-click={@on_clear}
        class="text-spotlight hover:text-spotlight-deep underline underline-offset-2"
      >
        Clear
      </a>
    </div>
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
        <.sort_button value="title" sort_by={@sort_by} class="px-3 py-1.5">By Title</.sort_button>
        <.sort_button value="venue" sort_by={@sort_by} class="px-3 py-1.5">By Venue</.sort_button>
      </div>
    </div>
    """
  end

  attr :value, :string, required: true
  attr :sort_by, :string, required: true
  attr :class, :string, required: true, doc: "the button's padding"
  slot :inner_block, required: true

  defp sort_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="sort-changed"
      phx-value-sort-by={@value}
      class={[
        "text-sm rounded-md transition-colors",
        @class,
        if(@sort_by == @value,
          do: "bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30",
          else: "text-paper-dim hover:text-paper"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </button>
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
        <.icon
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
          <.icon
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
                  <.venue_checkbox id={"#{venue.id}"} venue={venue} venue_ids={@venue_ids} />
                </span>
              </li>
            <% end %>
          </ul>
        </div>
      </.form>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :venue, :map, required: true
  attr :venue_ids, :list, required: true

  defp venue_checkbox(assigns) do
    ~H"""
    <input
      id={@id}
      name={@venue.id}
      value="true"
      type="checkbox"
      checked={Integer.to_string(@venue.id) in @venue_ids}
      class="rounded-sm border-hairline bg-ink-3 text-spotlight focus:ring-0 focus:ring-offset-0 cursor-pointer"
    />
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
    <.filter_status :if={@venue_ids != []} on_clear="clear-venue-filtering">
      Filtering by {Enum.count(@venue_ids)} venue(s).
    </.filter_status>
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
                  <.icon name="hero-x-mark" class="size-5" />
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
      <.icon
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
      <.filter_chip :if={@venue_ids != []} on_clear="clear-venue-filtering">
        {Enum.count(@venue_ids)} venue(s)
      </.filter_chip>
      <.filter_chip :if={@has_date_filter} on_clear="clear-date-filter">
        From {format_filter_date(@selected_date)}
      </.filter_chip>
    </div>
    """
  end

  attr :on_clear, :string, required: true, doc: "the event that clears the filter"
  slot :inner_block, required: true

  defp filter_chip(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 text-xs font-medium bg-spotlight/10 text-spotlight ring-1 ring-inset ring-spotlight/30 px-2.5 py-1 rounded-full">
      {render_slot(@inner_block)}
      <button type="button" phx-click={@on_clear} class="hover:text-spotlight-deep">
        <.icon name="hero-x-mark" class="size-3" />
      </button>
    </span>
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
                <.venue_checkbox id={"mobile-#{venue.id}"} venue={venue} venue_ids={@venue_ids} />
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
  Renders the search bar, with a typeahead dropdown of matching event titles.

  Deliberately a single piece of markup rather than the desktop/mobile pair the filters
  use: it sits high on the page, so on a phone the dropdown opens between the field and
  the on-screen keyboard rather than behind it.

  ## Example

  <.search_bar for={@form} search_term={@search_term} suggestions={@search_suggestions} />
  """

  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :search_term, :string, default: ""
  attr :suggestions, :list, default: []

  def search_bar(assigns) do
    ~H"""
    <div
      id="search-bar-component"
      phx-hook="SearchTypeahead"
      class="relative max-w-xl"
      phx-click-away={if @suggestions != [], do: "dismiss-suggestions"}
    >
      <.form for={@for} id="search-form" phx-change="search" phx-submit="submit-search">
        <label for="event-search" class="sr-only">Search events</label>
        <.icon
          name="hero-magnifying-glass"
          class="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-paper-dim"
        />
        <input
          type="search"
          id="event-search"
          name="q"
          value={@search_term}
          autocomplete="off"
          role="combobox"
          aria-expanded={to_string(@suggestions != [])}
          aria-controls="search-suggestions"
          enterkeyhint="search"
          maxlength="100"
          phx-debounce="300"
          placeholder="Search shows and artists"
          class={
            [
              "w-full rounded-lg border border-hairline bg-ink-2 py-2.5 pl-10 pr-10 text-paper",
              "placeholder:text-paper-dim focus:border-spotlight focus:ring-spotlight transition-colors",
              "[&::-webkit-search-cancel-button]:hidden",
              # 16px on phones is not a style choice: iOS Safari zooms the page in when you
              # focus an input smaller than that, and the zoomed layout is wider than the
              # screen, which is where the horizontal scrolling comes from. Back to the
              # 14px the other filter controls use once there is room for it.
              "text-base sm:text-sm"
            ]
          }
        />
        <button
          :if={@search_term != ""}
          type="button"
          phx-click="clear-search"
          aria-label="Clear search"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-paper-dim hover:text-paper transition-colors"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </.form>

      <ul
        :if={@suggestions != []}
        id="search-suggestions"
        role="listbox"
        class="absolute z-30 mt-2 max-h-60 w-full overflow-auto rounded-xl border border-hairline bg-ink-2 py-2 text-sm shadow-2xl shadow-black/50 sm:max-h-72"
      >
        <li :for={suggestion <- @suggestions}>
          <.link
            data-suggestion
            role="option"
            aria-selected="false"
            navigate={
              ~p"/events/#{suggestion.event_id}/#{MusicListingsWeb.SEO.slugify(suggestion.title || "event")}"
            }
            class="block px-4 py-2.5 text-paper hover:bg-ink-3 transition-colors"
          >
            <span class="block truncate">{suggestion.title}</span>
            <span class="block truncate text-xs text-paper-dim">
              {format_suggestion_date(suggestion.date)} · {suggestion.venue_name}{format_suggestion_openers(
                suggestion.openers
              )}
            </span>
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp format_suggestion_date(nil), do: ""
  defp format_suggestion_date(date), do: Calendar.strftime(date, "%a %b %-d")

  # Search matches the whole bill, so a suggestion can be here because of a support act.
  # Naming the openers is what makes that row make sense to the person who typed them.
  defp format_suggestion_openers(openers) when openers in [nil, []], do: ""
  defp format_suggestion_openers(openers), do: " · with " <> Enum.join(openers, ", ")

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
        <.sort_button value="title" sort_by={@sort_by} class="px-4 py-2">By Title</.sort_button>
        <.sort_button value="venue" sort_by={@sort_by} class="px-4 py-2">By Venue</.sort_button>
      </div>
    </div>
    """
  end
end
