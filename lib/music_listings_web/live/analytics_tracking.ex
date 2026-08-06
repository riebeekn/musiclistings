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
  chip ("list"). `ref` is the referrer captured from `?ref=` on the detail page
  and is always `nil` on the list pages, which have no such assign.
  """
  @spec track_resale_click(map(), String.t() | nil) :: :ok
  def track_resale_click(%{"id" => event_id, "surface" => surface}, ref) do
    :telemetry.execute(
      [:music_listings, :event, :resale_click],
      %{},
      %{event_id: event_id, surface: surface, ref: ref}
    )
  end
end
