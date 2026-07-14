defmodule MusicListingsWeb.Plugs.VisitorId do
  @moduledoc """
  Mints an anonymous, per-browser visitor id into the session.

  This is the only stable identifier the app has for anonymous traffic (public
  visitors are never logged in), and product analytics depends on it for two
  things: deduplicating impressions that a single visitor re-fires on LiveView
  reconnects, and attributing a ticket click to the surface the visitor arrived
  from. It is a random opaque id — it carries no personal data and is never
  joined to a user.
  """
  import Plug.Conn

  @session_key "visitor_id"

  @spec session_key() :: String.t()
  def session_key, do: @session_key

  @doc """
  Generates a fresh, opaque visitor id.
  """
  @spec generate() :: String.t()
  def generate do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, @session_key) do
      nil -> put_session(conn, @session_key, generate())
      _id -> conn
    end
  end
end
