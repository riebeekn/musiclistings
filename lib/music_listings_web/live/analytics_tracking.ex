defmodule MusicListingsWeb.AnalyticsTracking do
  @moduledoc """
  Shared telemetry emitters for LiveView-driven product analytics.

  Lives here rather than in each LiveView because the same click can originate
  from any page that renders the component in question — the TicketNetwork
  resale link, for instance, appears on the event detail page and in the list
  rows of both the events and venue-events pages.
  """

  @doc """
  Emitted when a TicketNetwork (resale) link is clicked.

  `surface` distinguishes the detail-page button ("detail") from the list-row
  chip ("list").
  """
  @spec track_resale_click(map()) :: :ok
  def track_resale_click(%{"id" => event_id, "surface" => surface}) do
    :telemetry.execute(
      [:music_listings, :event, :resale_click],
      %{},
      %{event_id: event_id, surface: surface}
    )
  end
end
