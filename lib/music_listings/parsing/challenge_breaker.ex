defmodule MusicListings.Parsing.ChallengeBreaker do
  @moduledoc """
  Remembers that a site has started answering a crawl with a bot-mitigation
  challenge, so a parser can stop sending it follow-up requests.

  A Cloudflare challenge is keyed on the client's bot score.  Once a crawl has
  drawn one, the rest of its requests draw it too, and every further request
  only adds to the volume that earned it.  A parser trips the breaker on a
  challenge, skips its optional requests (details pages, APIs) while it is
  tripped, and resets it when a request it can't do without - a listing page -
  gets through again.

  The state has to outlive any one process, as `MusicListings.Crawler.EventParser`
  parses each event in its own task.  It is keyed on the process that started
  the crawl (the root of a task's `$callers`), so two crawls - or two async
  tests - never see each other's trips.
  """
  use Agent

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(_opts) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  @doc """
  Marks `site` as challenged for the rest of this crawl.
  """
  @spec trip(term()) :: :ok
  def trip(site) do
    key = key(site)
    Agent.update(__MODULE__, &MapSet.put(&1, key))
  end

  @doc """
  Clears a trip, once `site` lets a request through again.
  """
  @spec reset(term()) :: :ok
  def reset(site) do
    key = key(site)
    Agent.update(__MODULE__, &MapSet.delete(&1, key))
  end

  @spec tripped?(term()) :: boolean()
  def tripped?(site) do
    key = key(site)
    Agent.get(__MODULE__, &MapSet.member?(&1, key))
  end

  defp key(site), do: {site, crawl_owner()}

  defp crawl_owner do
    :"$callers" |> Process.get([]) |> List.last(self())
  end
end
