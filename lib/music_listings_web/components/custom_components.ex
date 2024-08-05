defmodule MusicListingsWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.
  """

  use Phoenix.Component

  alias MusicListingsUtilities.DateHelpers

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
    <li class="py-1">
      <div class="min-w-0">
        <p class="text-lg leading-6 text-blue-900 font-semibold">
          <%= @event.title %>
        </p>
        <div class="mt-1 flex items-center gap-x-2 text-sm leading-5 text-blue-600 font-mono">
          <p><%= @event.venue.name %></p>
          <.event_price
            price_format={@event.price_format}
            price_lo={@event.price_lo}
            price_hi={@event.price_hi}
          />
          <.event_ticket_url ticket_url={@event.ticket_url} />
          <.event_details_url details_url={@event.details_url} />
        </div>
      </div>
    </li>
    """
  end

  defp event_details_url(%{details_url: nil} = assigns), do: ~H""

  defp event_details_url(assigns) do
    ~H"""
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
      $<%= @price_lo %>
    </p>
    """
  end

  defp event_price(%{price_format: :range} = assigns) do
    ~H"""
    <p>
      $<%= @price_lo %> - $<%= @price_hi %>
    </p>
    """
  end

  defp event_price(%{price_format: :variable} = assigns) do
    ~H"""
    $<%= @price_lo %>+
    """
  end
end
