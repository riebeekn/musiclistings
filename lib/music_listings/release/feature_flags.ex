# This is a CLI-style release task: it prints to stdout (captured by `render
# logs`) and turns operator-supplied flag names into atoms, so two checks that
# make sense for the web app don't apply here.
# credo:disable-for-this-file Credo.Check.Refactor.IoPuts
defmodule MusicListings.Release.FeatureFlags do
  @moduledoc """
  Enable / disable / list FunWithFlags feature flags from a release `eval`,
  without Mix installed.

  Invoked in production by `bin/enable_feature_flag` / `bin/disable_feature_flag`
  (see those scripts), which submit a one-off Render job running:

      /app/bin/music_listings eval 'MusicListings.Release.FeatureFlags.run(["enable", "my_flag"])'

  `eval` loads the code but does not start the application, so we boot only the
  pieces FunWithFlags needs (the repo + the `:fun_with_flags` app) before calling
  the public API. This mirrors how `MusicListings.Release.migrate/0` relies on
  `runtime.exs` to supply `DATABASE_URL`.
  """
  @app :music_listings

  def run(["enable", flag]),
    do: with_started(fn -> toggle(flag, &FunWithFlags.enable/1, "ENABLED") end)

  def run(["disable", flag]),
    do: with_started(fn -> toggle(flag, &FunWithFlags.disable/1, "DISABLED") end)

  def run(["list"]), do: with_started(&list/0)

  def run(other) do
    IO.puts("Usage: enable <flag> | disable <flag> | list  (got: #{inspect(other)})")
    System.stop(1)
  end

  defp toggle(flag, fun, label) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    name = String.to_atom(flag)
    {:ok, _enabled} = fun.(name)
    IO.puts("#{label}: #{flag}")
  end

  defp list do
    {:ok, flags} = FunWithFlags.all_flags()
    print_flags(Enum.sort_by(flags, & &1.name))
  end

  defp print_flags([]), do: IO.puts("No feature flags configured.")

  defp print_flags(flags) do
    IO.puts("Feature flags:")
    Enum.each(flags, &print_flag/1)
  end

  defp print_flag(flag) do
    state = if FunWithFlags.enabled?(flag.name), do: "enabled", else: "disabled"
    IO.puts("  #{flag.name}: #{state}")
  end

  # Boot the minimum needed to talk to the flag store via Ecto. `eval` starts no
  # applications, so we start the repo's dependencies and the repo itself.
  defp with_started(fun) do
    Application.load(@app)
    {:ok, _postgrex} = Application.ensure_all_started(:postgrex)
    {:ok, _ecto_sql} = Application.ensure_all_started(:ecto_sql)
    start_repo()
    {:ok, _fun_with_flags} = Application.ensure_all_started(:fun_with_flags)
    fun.()
  end

  defp start_repo do
    case MusicListings.Repo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end
end
