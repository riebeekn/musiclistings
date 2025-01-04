defmodule MusicListingsWeb.Plugs.HealthCheck do
  @moduledoc """
  Health check plug, see: https://jola.dev/posts/health-checks-for-plug-and-phoenix
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/health_check"} = conn, _opts) do
    conn
    |> send_resp(200, "OK")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
