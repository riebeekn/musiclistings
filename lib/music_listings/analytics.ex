defmodule MusicListings.Analytics do
  @moduledoc """
  Context for first-party product analytics.

  Records lightweight, telemetry-driven events (impressions, clicks) to the
  `analytics_events` table. Events are emitted via `:telemetry` at the call
  sites and persisted by `MusicListings.Analytics.TelemetryHandler`, keeping
  the measurement layer decoupled from any particular storage or vendor.
  """
  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListingsSchema.AnalyticsEvent

  @doc """
  Persists a single analytics event identified by `name`, with an optional
  free-form `metadata` map.
  """
  @spec record_event(String.t(), map()) ::
          {:ok, AnalyticsEvent.t()} | {:error, Ecto.Changeset.t()}
  def record_event(name, metadata \\ %{}) when is_binary(name) and is_map(metadata) do
    %AnalyticsEvent{name: name, metadata: metadata}
    |> Repo.insert()
  end

  @doc """
  Returns a map of event name => total count. Handy for a quick read in IEx,
  e.g. `MusicListings.Analytics.counts()`.
  """
  @spec counts() :: %{optional(String.t()) => non_neg_integer()}
  def counts do
    AnalyticsEvent
    |> group_by([event], event.name)
    |> select([event], {event.name, count(event.id)})
    |> Repo.all()
    |> Map.new()
  end
end
