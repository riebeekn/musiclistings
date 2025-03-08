defmodule MusicListings.Workers.PurgeEventsWorker do
  @moduledoc """
  Worker which purges historical events
  """
  use Oban.Worker

  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsUtilities.DateHelpers

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    one_month_ago = DateHelpers.today() |> Date.add(-30)
    Logger.info("Purging events older than #{one_month_ago}")

    from(event in Event, where: event.date < ^one_month_ago or is_nil(event.date))
    |> Repo.delete_all()

    :ok
  end
end
