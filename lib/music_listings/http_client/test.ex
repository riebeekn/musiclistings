defmodule MusicListings.HttpClient.Test do
  @moduledoc """
  Test HttpClient implementation that serves fixture files for known
  URL patterns and returns errors for everything else. This allows
  parsers that fetch detail pages to exercise their actual parsing
  logic in tests rather than only testing fallback paths.
  """
  @behaviour MusicListings.HttpClient

  alias MusicListings.HttpClient.Response

  @fixture_base "test/data"

  @impl true
  def get(url, _headers \\ []) do
    case fixture_for_url(url) do
      {:ok, body} -> {:ok, Response.new(200, body)}
      :error -> {:error, :test_env}
    end
  end

  @impl true
  def post(_url, _body, _headers), do: {:error, :test_env}

  defp fixture_for_url(url) do
    url
    |> match_fixture()
    |> read_fixture()
  end

  defp match_fixture(url) do
    Enum.find_value(fixtures(), fn {pattern, fixture_path} ->
      if String.contains?(url, pattern), do: fixture_path
    end)
  end

  defp read_fixture(nil), do: :error

  defp read_fixture(fixture_path) do
    @fixture_base
    |> Path.join(fixture_path)
    |> File.read()
    |> case do
      {:ok, body} -> {:ok, body}
      {:error, _reason} -> :error
    end
  end

  defp fixtures do
    [
      # Roy Thomson Hall
      {"roythomsonhall.mhrth.com/api/attendable", "roy_thomson_hall/instances.json"},
      {"roythomsonhall.mhrth.com/tickets/", "roy_thomson_hall/detail.html"},
      # Massey Hall
      {"masseyhall.mhrth.com/api/attendable", "massey_hall/instances.json"},
      {"masseyhall.mhrth.com/tickets/", "massey_hall/detail.html"},
      # TD Music Hall
      {"tdmusichall.mhrth.com/api/attendable", "td_music_hall/instances.json"},
      {"tdmusichall.mhrth.com/tickets/", "td_music_hall/detail.html"},
      # Drake Underground
      {"thedrake.ca/event/", "drake_underground/detail.html"}
    ]
  end
end
