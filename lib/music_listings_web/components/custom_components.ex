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

  # TODO: get rid of this if end up not using it
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
        <%= @header %>
      </h1>
      <p :if={@description} class="mt-4 text-md">
        <%= @description %>
      </p>
    </div>
    """
  end

  # TODO: get rid of this if end up not using it
  @doc """
  Renders a 2 column header

  ## Example

  <.two_column_header header="Events">
    <:secondary_item>
      <.button_link label="Submit a new event / venue" url="#" icon_name="hero-arrow-right" />
    </:secondary_item>
  </.two_column_header>
  """
  attr :header, :string, required: true
  slot :secondary_item, required: true

  def two_column_header(assigns) do
    ~H"""
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h1 class="text-3xl font-bold leading-7 text-zinc-200 sm:truncate sm:text-4xl sm:tracking-tight">
          <%= @header %>
        </h1>
      </div>

      <div class="mt-4 flex md:ml-4 md:0">
        <%= render_slot(@secondary_item) %>
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
      class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full py-1 px-3 bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:bg-emerald-400/10 hover:text-emerald-300 hover:ring-emerald-300"
    >
      <%= if @icon_name && @icon_position == :left do %>
        <MusicListingsWeb.CoreComponents.icon name={@icon_name} class="size-3 mt-1 mr-1" />
      <% end %>
      <%= @label %>
      <%= if @icon_name && @icon_position == :right do %>
        <MusicListingsWeb.CoreComponents.icon name={@icon_name} class="size-3 mt-1 ml-1" />
      <% end %>
    </.link>
    """
  end

  @doc """
  Renders a date header

  ## Example

  <.events_date_header date={date} />
  """
  attr :date, Date, required: true

  def events_date_header(assigns) do
    ~H"""
    <h2 class="text-left text-3xl font-semibold leading-5 text-zinc-400 sm:text-4xl sm:tracking-tight">
      <time datetime={@date}><%= DateHelpers.format_date(@date) %></time>
    </h2>
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
  Renders information about a venue

  ## Example

  <.venue_card venue={@venue} />
  """
  def venue_card(assigns) do
    ~H"""
    <div class="block sm:flex text-zinc-200">
      <div class="pr-12 whitespace-nowrap">
        <h2 class="text-4xl font-bold">
          <%= @venue.name %>
        </h2>
        <div class="ml-1 mt-2 text-md leading-5">
          <span class="block"><%= @venue.street %></span>
          <span class="block"><%= "#{@venue.city} #{@venue.province}" %></span>
          <span class="block"><%= "#{@venue.country} #{@venue.postal_code}" %></span>
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
                      <%= venue.name %>
                      <dl class="sm:hidden">
                        <dt class="sr-only">Street</dt>
                        <dd class="text-zinc-400"><%= venue.street %></dd>
                        <dt class="sr-only">Upcoming Events</dt>
                        <dd class="text-zinc-400">
                          <a
                            href={~p"/events/venue/#{venue.id}"}
                            class="text-emerald-400 hover:text-emerald-500"
                          >
                            <%= venue.upcoming_event_count %> Upcoming Events
                          </a>
                        </dd>
                      </dl>
                    </td>
                    <td class="hidden sm:table-cell whitespace-nowrap px-3 py-4 text-sm text-zinc-400">
                      <%= venue.street %>
                    </td>
                    <td class="hidden sm:table-cell whitespace-nowrap py-4 pl-3 text-right text-sm font-medium">
                      <a
                        href={~p"/events/venue/#{venue.id}"}
                        class="text-emerald-400 hover:text-emerald-500"
                      >
                        <%= venue.upcoming_event_count %> Upcoming Events
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
  Renders a table of events for the passed in events

  ## Example

  <.events_table events={events} />
  """
  attr :events, :list, required: true

  def events_table(assigns) do
    ~H"""
    <table class="table-fixed min-w-full">
      <tbody class="divide-y divide-zinc-600">
        <%= for {date, events} <- @events do %>
          <tr>
            <th scope="colgroup" colspan="3" class="py-8 sm:py-6">
              <.events_date_header date={date} />
            </th>
          </tr>
          <%= for event <- events do %>
            <tr id={"event-#{event.id}"}>
              <td class="py-4 align-top w-4/8">
                <.event_title title={event.title} />
                <div class="mt-1 text-sm sm:flex sm:gap-x-2">
                  <.event_ticket_url
                    ticket_url={event.ticket_url}
                    price_format={event.price_format}
                    price_lo={event.price_lo}
                    price_hi={event.price_hi}
                  />
                  <.event_details_url details_url={event.details_url} />
                </div>
              </td>

              <td class="py-4 align-top w-3/8 pl-1">
                <.event_venue venue={event.venue} />
                <.event_time time={event.time} />
              </td>
              <td class="py-3 align-top w-1/8 text-right">
                <.event_age_restriction age_restriction={event.age_restriction} />
              </td>
            </tr>
          <% end %>
        <% end %>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a table of events for the passed in events, specific to a single venue

  ## Example

  <.venue_events_table events={events} />
  """
  attr :events, :list, required: true

  def venue_events_table(assigns) do
    ~H"""
    <table class="table-fixed min-w-full">
      <tbody class="divide-y divide-zinc-600">
        <%= for event <- @events do %>
          <tr id={"event-#{event.id}"}>
            <td class="align-top py-2 w-2/8">
              <.event_date date={event.date} />
              <.event_time time={event.time} />
            </td>
            <td class="align-top py-2 pl-4 w-5/8">
              <.event_title title={event.title} />

              <div class="mt-1 text-xs leading-5 flex gap-x-2">
                <.event_ticket_url
                  ticket_url={event.ticket_url}
                  price_format={event.price_format}
                  price_lo={event.price_lo}
                  price_hi={event.price_hi}
                />
                <.event_details_url details_url={event.details_url} />
              </div>
            </td>
            <td class="align-top py-2 w-1/8 text-right">
              <.event_age_restriction age_restriction={event.age_restriction} />
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp event_date(assigns) do
    ~H"""
    <div class="text-sm font-medium leading-6 text-emerald-400">
      <span><%= DateHelpers.format_date(@date) %></span>
    </div>
    """
  end

  defp event_title(assigns) do
    ~H"""
    <div class="text-md font-medium leading-6 text-white uppercase">
      <%= @title %>
    </div>
    """
  end

  defp event_ticket_url(%{ticket_url: nil} = assigns), do: ~H""

  defp event_ticket_url(assigns) do
    ~H"""
    <a
      href={@ticket_url}
      class="sm:flex sm:items-center text-emerald-400 hover:text-emerald-500"
      target="_blank"
    >
      <div class="block sm:hidden sm:ml-1">
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </div>
      <div class="flex items-center">
        <MusicListingsWeb.CoreComponents.icon name="hero-ticket-solid" class="size-4" />
        <div class="ml-1">
          Tickets
        </div>
      </div>
      <div class="hidden sm:block sm:ml-1">
        <.event_price price_format={@price_format} price_lo={@price_lo} price_hi={@price_hi} />
      </div>
    </a>
    """
  end

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    ~H"""
    <a
      href={@details_url}
      class="flex items-center text-emerald-400 hover:text-emerald-500"
      target="_blank"
    >
      <MusicListingsWeb.CoreComponents.icon name="hero-information-circle-solid" class="size-4" />
      <span class="ml-1">Details</span>
    </a>
    """
  end

  defp event_age_restriction(%{age_restriction: :unknown} = assigns), do: ~H""

  defp event_age_restriction(assigns) do
    ~H"""
    <div class="whitespace-nowrap mr-4 rounded-md text-xs inline-flex gap-0.5 justify-center overflow-hidden font-medium transition py-1 px-3 bg-amber-400/10 text-amber-400 ring-1 ring-inset ring-amber-400/20 hover:bg-amber-400/10 hover:text-amber-300 hover:ring-amber-300">
      <%= format_age_restriction(@age_restriction) %>
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
      class="text-md font-medium leading-4 text-emerald-400 hover:text-emerald-500"
    >
      <%= @venue.name %>
    </a>
    """
  end

  defp event_time(%{time: nil} = assigns), do: ~H""

  defp event_time(assigns) do
    ~H"""
    <div class="mt-1 text-sm">
      <time class="text-zinc-400"><%= DateHelpers.format_time(@time) %></time>
    </div>
    """
  end

  defp event_price(%{price_format: :unknown} = assigns), do: ~H""

  defp event_price(%{price_format: :free} = assigns) do
    ~H"""
    $FREE
    """
  end

  defp event_price(%{price_format: :fixed} = assigns) do
    ~H"""
    $<%= @price_lo %>
    """
  end

  defp event_price(%{price_format: :range} = assigns) do
    ~H"""
    $<%= @price_lo %> - $<%= @price_hi %>
    """
  end

  defp event_price(%{price_format: :variable} = assigns) do
    ~H"""
    $<%= @price_lo %>+
    """
  end
end
