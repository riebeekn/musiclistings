defmodule MusicListingsWeb.VisitorTracking do
  @moduledoc """
  `on_mount` hook that makes the anonymous visitor id (minted by
  `MusicListingsWeb.Plugs.VisitorId`) and the request's user agent available to
  every LiveView, so analytics emitters can stamp them onto their telemetry
  metadata.

  The user agent comes from the socket's connect info rather than the session:
  it is only present on the connected mount, which is fine because every
  analytics emitter is guarded on `connected?/1`.
  """
  import Phoenix.Component, only: [assign_new: 3]
  import Phoenix.LiveView, only: [get_connect_info: 2]

  alias MusicListingsWeb.Plugs.VisitorId

  def on_mount(:assign_visitor, _params, session, socket) do
    socket =
      socket
      |> assign_new(:visitor_id, fn -> session[VisitorId.session_key()] end)
      |> assign_new(:user_agent, fn -> get_connect_info(socket, :user_agent) end)

    {:cont, socket}
  end
end
