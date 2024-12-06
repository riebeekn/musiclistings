defmodule MusicListingsWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.
  """

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MusicListingsWeb.Endpoint,
    router: MusicListingsWeb.Router,
    statics: MusicListingsWeb.static_paths()

  alias MusicListingsUtilities.DateHelpers
  alias Phoenix.LiveView.JS

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
    <div class="min-w-0 flex-1 text-zinc-400">
      <h1 class="text-3xl font-bold leading-7 sm:truncate sm:text-4xl sm:tracking-tight">
        {@header}
      </h1>
      <p :if={@description} class="mt-4 text-md">
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
    <div class="relative px-6 sm:pb-20 pt-6 sm:pt-32 lg:static lg:px-8 lg:py-48">
      <div class="mx-auto max-w-xl lg:mx-0 lg:max-w-lg">
        <h1 class="text-pretty text-4xl font-semibold tracking-tight text-white sm:text-5xl">
          {@header}
        </h1>
        <div class="text-lg/8 text-zinc-300 mt-6 space-y-6">
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
      class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full py-1 px-3 bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:text-emerald-300 hover:ring-emerald-300"
    >
      <%= if @icon_name && @icon_position == :left do %>
        <MusicListingsWeb.CoreComponents.icon name={@icon_name} class="size-3 mt-1 mr-1" />
      <% end %>
      {@label}
      <%= if @icon_name && @icon_position == :right do %>
        <MusicListingsWeb.CoreComponents.icon name={@icon_name} class="size-3 mt-1 ml-1" />
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
    <div class="flex justify-center mt-36 text-emerald-400">
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
    <div class="space-x-2">
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
      <a
        href="#"
        phx-click={toggle_venue_filtering()}
        class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full py-1 px-3 bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:text-emerald-300 hover:ring-emerald-300"
      >
        Filter by venue
        <span id="venue-filter-chevron" class="inline-block transition duration-200">
          <MusicListingsWeb.CoreComponents.icon name="hero-chevron-down" class="size-4" />
        </span>
      </a>

      <.form for={@for} as={:for} id="venue-filters" class="hidden" phx-change="venue-filter-selected">
        <div class="relative" phx-click-away={toggle_venue_filtering()}>
          <ul
            class="absolute z-10 mt-1 max-h-60 w-full min-w-80 overflow-auto rounded-md bg-zinc-900 py-1 text-base shadow-lg ring-1 ring-inset ring-white/10 hover:ring-white/20 "
            tabindex="-1"
          >
            <%= for venue <- @venues do %>
              <li
                class="relative cursor-default select-none py-2 pl-8 pr-4 text-white ml-4 text-sm font-semibold leading-7"
                role="option"
              >
                <span class="block truncate">
                  <label for={"#{venue.id}"}>{venue.name}</label>
                </span>
                <span class="absolute inset-y-0 left-0 flex items-center pl-1.5">
                  <input
                    id={"#{venue.id}"}
                    name={venue.id}
                    value="true"
                    type="checkbox"
                    checked={Integer.to_string(venue.id) in @venue_ids}
                    class="focus:ring-0  border-none focus:ring-0 focus:ring-offset-0 bg-zinc-300 text-zinc-600"
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
      <div class="text-white text-sm sm:text-base -mt-4 sm:-mt-1 mb-6 sm:mb-4">
        Filtering by {Enum.count(@venue_ids)} venue(s).
        <a href="#" phx-click="clear-venue-filtering" class="text-emerald-400 hover:text-emerald-300">
          Clear filter.
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
    <div class="block sm:flex text-zinc-200">
      <div class="pr-12 sm:whitespace-nowrap">
        <h2 class="text-4xl font-bold">
          {@venue.name}
        </h2>
        <div class="ml-1 mt-2 text-md leading-5">
          <span class="block">{@venue.street}</span>
          <span class="block">{"#{@venue.city} #{@venue.province}"}</span>
          <span class="block">{"#{@venue.country} #{@venue.postal_code}"}</span>
          <span class="block mt-1">
            <a
              href={@venue.website}
              class="flex items-center gap-x-1 text-emerald-400 hover:text-emerald-500"
              target="_blank"
            >
              <MusicListingsWeb.CoreComponents.icon name="hero-arrow-right" class="size-4" /> Website
            </a>
          </span>
        </div>
      </div>

      <div class="relative w-full h-36 my-8 sm:my-0">
        <iframe
          class="absolute top-0 left-0 w-full h-full"
          src={@venue.google_map_url}
          frameborder="0"
          style="border:0;"
          allowfullscreen=""
          aria-hidden="false"
          tabindex="0"
          loading="lazy"
          referrerpolicy="no-referrer-when-downgrade"
        >
        </iframe>
      </div>
    </div>
    """
  end

  @doc """
  Renders a tables of venue summary information

  ## Example

  <.venue_summary venues={@venues} />
  """
  attr :venues, :list, required: true

  def venue_summary(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mt-0 sm:mt-4 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <table class="w-full">
              <thead class="sr-only">
                <tr>
                  <th>Venue Name</th>
                  <th>Street</th>
                  <th>Upcoming Events</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-700">
                <%= for venue <- @venues do %>
                  <tr id={"venue-#{venue.id}"}>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                      {venue.name}
                      <dl class="sm:hidden">
                        <dt class="sr-only">Street</dt>
                        <dd class="text-zinc-400">{venue.street}</dd>
                        <dt class="sr-only">Upcoming Events</dt>
                        <dd class="text-zinc-400">
                          <a
                            href={~p"/events/venue/#{venue.id}"}
                            class="text-emerald-400 hover:text-emerald-500"
                          >
                            {venue.upcoming_event_count} Upcoming Events
                          </a>
                        </dd>
                      </dl>
                    </td>
                    <td class="hidden sm:table-cell whitespace-nowrap px-3 py-4 text-sm text-zinc-400">
                      {venue.street}
                    </td>
                    <td class="hidden sm:table-cell whitespace-nowrap py-4 pl-3 text-right text-sm font-medium">
                      <a
                        href={~p"/events/venue/#{venue.id}"}
                        class="text-emerald-400 hover:text-emerald-500"
                      >
                        {venue.upcoming_event_count} Upcoming Events
                      </a>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
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
    <dl>
      <%= for {date, events} <- @events do %>
        <dt class="mb-2">
          <.events_date_header date={date} />
        </dt>
        <dl class="divide-y divide-zinc-600 mb-12">
          <%= for event <- events do %>
            <div id={"event-#{event.id}"} class="py-2">
              <dt class="flex items-center justify-between sm:justify-start sm:gap-x-2">
                <.event_venue venue={event.venue} />
                <.event_age_restriction age_restriction={event.age_restriction} />
              </dt>
              <dd class="mt-0 sm:mt-1 flex justify-between">
                <.event_title_section event={event} current_user={@current_user} />
              </dd>
              <dd class="flex items-center gap-x-2 mt-0 sm:mt-1">
                <.event_time time={event.time} />
                <.event_ticket_url
                  ticket_url={event.ticket_url}
                  price_format={event.price_format}
                  price_lo={event.price_lo}
                  price_hi={event.price_hi}
                />
                <.event_details_url details_url={event.details_url} />
              </dd>
            </div>
          <% end %>
        </dl>
      <% end %>
    </dl>
    """
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
    <dl class="divide-y divide-zinc-600">
      <%= for event <- @events do %>
        <div id={"event-#{event.id}"} class="py-2 sm:py-4">
          <dt class="flex items-center justify-between sm:justify-start sm:gap-x-2">
            <div class="flex items-center gap-x-1">
              <.event_date date={event.date} />
              <.event_time time={event.time} />
            </div>
            <div>
              <.event_age_restriction age_restriction={event.age_restriction} />
            </div>
          </dt>
          <dd class="mt-0 sm:mt-1 flex justify-between">
            <.event_title_section event={event} current_user={@current_user} />
          </dd>
          <dd class="flex items-center gap-x-2 mt-0 sm:mt-1">
            <.event_ticket_url
              ticket_url={event.ticket_url}
              price_format={event.price_format}
              price_lo={event.price_lo}
              price_hi={event.price_hi}
            />
            <.event_details_url details_url={event.details_url} />
          </dd>
        </div>
      <% end %>
    </dl>
    """
  end

  defp events_date_header(assigns) do
    ~H"""
    <h2 class="text-left text-3xl font-semibold leading-5 text-zinc-400 sm:text-4xl sm:tracking-tight">
      <time datetime={@date}>{DateHelpers.format_date(@date)}</time>
    </h2>
    """
  end

  defp event_date(assigns) do
    ~H"""
    <div class="text-xs sm:text-sm font-medium leading-4 text-zinc-400">
      <span>{DateHelpers.format_date(@date)}</span>
    </div>
    """
  end

  defp event_title_section(assigns) do
    ~H"""
    <.event_title event={@event} />
    <%= if @current_user do %>
      <button
        phx-click="delete-event"
        phx-value-id={@event.id}
        data-confirm="Are you sure?"
        class="text-white"
      >
        Delete
      </button>
    <% end %>
    """
  end

  defp event_title(assigns) do
    ~H"""
    <div class="text-sm sm:text-lg font-medium leading-6 text-white uppercase">
      {@event.title}
      <%= if @event.openers != [] do %>
        with {@event.openers |> Enum.join(", ")}
      <% end %>
    </div>
    """
  end

  defp event_ticket_url(assigns) do
    ~H"""
    <%= if @ticket_url do %>
      <a
        href={@ticket_url}
        class="flex items-center text-xs sm:text-sm text-emerald-400 hover:text-emerald-500"
        target="_blank"
      >
        <div class="flex items-center">
          <MusicListingsWeb.CoreComponents.icon
            name="hero-ticket-solid"
            class="hidden sm:block size-4"
          />
          <div class="sm:ml-1">
            Tickets
          </div>
        </div>
        <div class="ml-1">
          <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
        </div>
      </a>
    <% end %>
    <%= if @price_format != :unknown && !@ticket_url do %>
      <div class="text-xs sm:text-sm text-emerald-400">
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </div>
    <% end %>
    """
  end

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    ~H"""
    <a
      href={@details_url}
      class="flex items-center text-xs text-emerald-400 hover:text-emerald-500"
      target="_blank"
    >
      <MusicListingsWeb.CoreComponents.icon
        name="hero-information-circle-solid"
        class="hidden sm:block size-4"
      />
      <span class="sm:ml-1">Details</span>
    </a>
    """
  end

  defp event_age_restriction(%{age_restriction: :unknown} = assigns), do: ~H""

  defp event_age_restriction(assigns) do
    ~H"""
    <div class="text-xs sm:text-sm whitespace-nowrap text-amber-400">
      ({format_age_restriction(@age_restriction)})
    </div>
    """
  end

  defp format_age_restriction(:all_ages), do: "All Ages"
  defp format_age_restriction(:eighteen_plus), do: "18+"
  defp format_age_restriction(:nineteen_plus), do: "19+"

  defp event_venue(assigns) do
    ~H"""
    <a
      href={~p"/events/venue/#{@venue.id}"}
      class="text-xs sm:text-sm font-medium leading-4 text-emerald-400 hover:text-emerald-500"
    >
      {@venue.name}
    </a>
    """
  end

  defp event_time(%{time: nil} = assigns), do: ~H""

  defp event_time(assigns) do
    ~H"""
    <time class="text-xs sm:text-sm text-zinc-400">{DateHelpers.format_time(@time)}</time>
    """
  end

  defp event_price(%{price_format: :unknown} = assigns), do: ~H""

  defp event_price(%{price_format: :free} = assigns) do
    ~H"""
    $FREE
    """
  end

  defp event_price(%{price_format: :pwyc} = assigns) do
    ~H"""
    $PWYC
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
end
