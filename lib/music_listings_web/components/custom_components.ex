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

  attr :label, :string, required: true
  attr :url, :string, required: true

  def button_patch_link(assigns) do
    ~H"""
    <.link
      patch={@url}
      data-scroll="top"
      class="inline-flex justify-center rounded-2xl bg-blue-600 p-4 text-base font-semibold text-white hover:bg-blue-500 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 active:text-white/70"
    >
      <%= @label %>
    </.link>
    """
  end

  attr :date, Date, required: true

  def events_date_header(assigns) do
    ~H"""
    <h2 class="text-3xl text-blue-600 font-bold">
      <%= DateHelpers.format_date(@date) %>
    </h2>
    """
  end

  attr :event, MusicListingsSchema.Event, required: true

  def event_card(assigns) do
    ~H"""
    <li id={"event-#{@event.id}"} class="py-1">
      <div class="min-w-0">
        <.event_title title={@event.title} />
        <div class="mt-1 flex items-center gap-x-2 text-sm leading-5 text-blue-600 font-mono">
          <.event_venue venue={@event.venue} />
          <.event_price
            price_format={@event.price_format}
            price_lo={@event.price_lo}
            price_hi={@event.price_hi}
          />
          <.event_time time={@event.time} />
          <.event_details_url details_url={@event.details_url} />
          <.event_ticket_url ticket_url={@event.ticket_url} />
        </div>
      </div>
    </li>
    """
  end

  attr :event, MusicListingsSchema.Event, required: true

  def venue_event_card(assigns) do
    ~H"""
    <li id={"event-#{@event.id}"} class="py-1">
      <div class="min-w-0 text-sm leading-5 text-blue-600 font-mono">
        <.event_title_small title={@event.title} />
        <div class="mt-0 flex items-center gap-x-2 ">
          <.event_date date={@event.date} />
          <.event_price
            price_format={@event.price_format}
            price_lo={@event.price_lo}
            price_hi={@event.price_hi}
          />
          <.event_time time={@event.time} />
          <.event_details_url details_url={@event.details_url} />
          <.event_ticket_url ticket_url={@event.ticket_url} />
        </div>
      </div>
    </li>
    """
  end

  defp event_title_small(assigns) do
    ~H"""
    <span class="font-semibold italic"><%= @title %></span>
    """
  end

  defp event_date(assigns) do
    ~H"""
    <p>
      <span class="font-semibold"><%= DateHelpers.format_date(@date) %></span>
    </p>
    """
  end

  defp event_title(assigns) do
    ~H"""
    <p class="text-lg leading-6 text-blue-900 font-semibold">
      <%= @title %>
    </p>
    """
  end

  defp event_venue(assigns) do
    ~H"""
    <a href={~p"/events/venue/#{@venue.id}"}>
      <%= @venue.name %>
    </a>
    """
  end

  defp event_time(%{time: nil} = assigns), do: ~H""

  defp event_time(assigns) do
    ~H"""
    <p>
      |
    </p>
    <%= DateHelpers.format_time(@time) %>
    """
  end

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    ~H"""
    <p>
      |
    </p>
    <p>
      <a href={@details_url} target="_blank" class="flex items-center">
        <MusicListingsWeb.CoreComponents.icon name="hero-information-circle-solid" class="h-5 w-5" />
        <span class="ml-1">Details</span>
      </a>
    </p>
    """
  end

  defp event_ticket_url(%{ticket_url: nil} = assigns), do: ~H""

  defp event_ticket_url(assigns) do
    ~H"""
    <p>
      |
    </p>
    <p>
      <a href={@ticket_url} target="_blank" class="flex items-center">
        <MusicListingsWeb.CoreComponents.icon name="hero-ticket-solid" class="h-5 w-5" />
        <span class="ml-1">Tickets</span>
      </a>
    </p>
    """
  end

  defp event_price(%{price_format: :unknown} = assigns), do: ~H""

  defp event_price(%{price_format: :fixed} = assigns) do
    ~H"""
    <p>
      |
    </p>
    <p>
      $<%= @price_lo %>
    </p>
    """
  end

  defp event_price(%{price_format: :range} = assigns) do
    ~H"""
    <p>
      |
    </p>
    <p>
      $<%= @price_lo %> - $<%= @price_hi %>
    </p>
    """
  end

  defp event_price(%{price_format: :variable} = assigns) do
    ~H"""
    <p>
      |
    </p>
    $<%= @price_lo %>+
    """
  end

  def venue_card(assigns) do
    ~H"""
    <div class="flex">
      <div class="w-full">
        <h2 class="text-3xl text-blue-600 font-bold">
          <%= @venue.name %>
        </h2>
        <div class="ml-1 text-sm leading-5 text-blue-600 font-mono">
          <span class="block"><%= @venue.street %></span>
          <span class="block"><%= "#{@venue.city} #{@venue.province}" %></span>
          <span class="block"><%= "#{@venue.country} #{@venue.postal_code}" %></span>
        </div>
      </div>

      <div class="hidden sm:block relative w-full h-36">
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
end
