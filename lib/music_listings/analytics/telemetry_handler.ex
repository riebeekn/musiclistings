defmodule MusicListings.Analytics.TelemetryHandler do
  @moduledoc """
  Attaches to the app's product-analytics `:telemetry` events and persists each
  one via `MusicListings.Analytics`.

  Attach once at application boot with `attach/0`. Handlers must never raise —
  `:telemetry` permanently detaches a handler that throws — so each insert is
  wrapped and any failure is logged rather than propagated.
  """
  alias MusicListings.Analytics

  require Logger

  @handler_id "music-listings-analytics"

  @events [
    [:music_listings, :new_this_week, :shown],
    [:music_listings, :new_this_week, :card_click],
    [:music_listings, :event, :ticket_link_shown],
    [:music_listings, :event, :ticket_click]
  ]

  @doc """
  Attaches the handler to the analytics telemetry events. Idempotent — safe to
  call on every boot (it detaches any prior registration first).
  """
  @spec attach() :: :ok | {:error, :already_exists}
  def attach do
    :telemetry.detach(@handler_id)
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil)
  end

  @doc false
  def handle_event([:music_listings, :new_this_week, :shown], _measurements, metadata, _config) do
    record("new_this_week.shown", visitor_fields(metadata))
  end

  def handle_event(
        [:music_listings, :new_this_week, :card_click],
        _measurements,
        metadata,
        _config
      ) do
    record(
      "new_this_week.card_click",
      metadata |> visitor_fields() |> Map.put("event_id", metadata[:event_id])
    )
  end

  def handle_event(
        [:music_listings, :event, :ticket_link_shown],
        _measurements,
        metadata,
        _config
      ) do
    record(
      "event.ticket_link_shown",
      metadata
      |> visitor_fields()
      |> Map.merge(%{"event_id" => metadata[:event_id], "ref" => metadata[:ref]})
    )
  end

  def handle_event(
        [:music_listings, :event, :ticket_click],
        _measurements,
        metadata,
        _config
      ) do
    record(
      "event.ticket_click",
      metadata
      |> visitor_fields()
      |> Map.merge(%{"event_id" => metadata[:event_id], "ref" => metadata[:ref]})
    )
  end

  # Every event carries the visitor id (for dedup and cross-pageview
  # attribution) and the user agent (so bots can be filtered out at report time
  # rather than dropped at write time).
  defp visitor_fields(metadata) do
    %{
      "visitor_id" => metadata[:visitor_id],
      "user_agent" => metadata[:user_agent]
    }
  end

  defp record(name, metadata) do
    Analytics.record_event(name, metadata)
    :ok
  rescue
    error ->
      Logger.error("[analytics] failed to record #{name}: #{inspect(error)}")
      :ok
  end
end
