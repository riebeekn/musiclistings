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
    [:music_listings, :recently_added, :shown],
    [:music_listings, :recently_added, :card_click],
    [:music_listings, :recently_added, :ticket_click]
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
  def handle_event([:music_listings, :recently_added, :shown], measurements, _metadata, _config) do
    record("recently_added.shown", %{"count" => measurements[:count]})
  end

  def handle_event(
        [:music_listings, :recently_added, :card_click],
        _measurements,
        metadata,
        _config
      ) do
    record("recently_added.card_click", %{"event_id" => metadata[:event_id]})
  end

  def handle_event(
        [:music_listings, :recently_added, :ticket_click],
        _measurements,
        metadata,
        _config
      ) do
    record("recently_added.ticket_click", %{"event_id" => metadata[:event_id]})
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
