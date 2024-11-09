defmodule MusicListingsWeb.UserLoginLive do
  use MusicListingsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.page_header header="Login" />

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <div class="flex justify-start space-x-4 items-center">
          <.input field={@form[:remember_me]} type="checkbox" />
          <label class="text-white">Keep me logged in</label>
        </div>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full bg-zinc-600">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
