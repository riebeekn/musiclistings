defmodule MusicListings.Venues do
  @moduledoc """
  Context module for venue related functionality
  """
  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias MusicListingsUtilities.DateHelpers

  @spec list_venues :: list(VenueSummary)
  def list_venues(opts \\ []) do
    restrict_to_pulled_venues? = Keyword.get(opts, :restrict_to_pulled_venues?, true)
    today = DateHelpers.now() |> DateHelpers.to_eastern_date()

    Venue
    |> join(:left, [venue], event in Event,
      on: event.venue_id == venue.id and event.date >= ^today
    )
    |> maybe_restrict_to_pulled_venues(restrict_to_pulled_venues?)
    |> group_by([venue], [venue.id, venue.name, venue.street])
    |> order_by([venue], venue.name)
    |> select([venue, event], %{
      id: venue.id,
      name: venue.name,
      street: venue.street,
      event_count: count(event.id)
    })
    |> Repo.all()
    |> Enum.map(&VenueSummary.new/1)
  end

  defp maybe_restrict_to_pulled_venues(query, false), do: query

  defp maybe_restrict_to_pulled_venues(query, true) do
    query
    |> where([venue], venue.pull_events?)
  end

  @spec get_venue!(pos_integer()) :: Venue
  def get_venue!(venue_id), do: Repo.get!(Venue, venue_id)

  def fetch_venue_by_name(venue_name) do
    from(venue in Venue, where: fragment("lower(?) = lower(?)", venue.name, ^venue_name))
    |> Repo.one()
    |> case do
      nil -> {:error, :venue_not_found}
      venue -> {:ok, venue}
    end
  end
end
