defmodule MusicListingsWeb.NavbarComponents do
  @moduledoc """
  Navbar related components
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MusicListingsWeb.Endpoint,
    router: MusicListingsWeb.Router,
    statics: MusicListingsWeb.static_paths()

  import MusicListingsWeb.CoreComponents, only: [icon: 1]
  import MusicListingsWeb.CustomComponents, only: [when_admin: 1]
  alias Phoenix.LiveView.JS

  @doc """
  Renders the navbar

  ## Example

  <.navbar />
  """
  def navbar(assigns) do
    ~H"""
    <nav class="sticky top-0 z-50 bg-neutral-950/80 backdrop-blur-xl border-b border-neutral-800">
      <.mobile_updated_banner current_user={@current_user} />
      <.main_menu current_user={@current_user} />
      <.mobile_menu current_user={@current_user} />
    </nav>
    """
  end

  defp main_menu(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl px-5 sm:px-8 lg:px-10">
      <div class="relative flex h-16 items-center justify-between">
        <.mobile_menu_button />
        <.main_menu_links current_user={@current_user} />
        <div class="hidden md:flex items-center gap-4">
          <.last_updated_label />
          <a
            href={~p"/events/new"}
            class="bg-rose-500 hover:bg-rose-400 text-neutral-950 font-semibold text-sm px-4 py-2 rounded-lg transition-colors"
          >
            + Submit Event
          </a>
          <.when_admin current_user={@current_user}>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="text-sm text-rose-400 font-semibold hover:text-rose-300 transition-colors"
            >
              Log out
            </.link>
          </.when_admin>
        </div>
      </div>
    </div>
    """
  end

  defp mobile_updated_banner(assigns) do
    ~H"""
    <div class="block md:hidden border-b border-neutral-800 py-2.5">
      <div class="mx-auto flex flex-col items-center px-4">
        <.last_updated_label />
        <.when_admin current_user={@current_user}>
          <div class="mt-1">
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="text-xs text-rose-400 font-semibold hover:text-rose-300"
            >
              Log out
            </.link>
          </div>
        </.when_admin>
      </div>
    </div>
    """
  end

  defp mobile_menu_button(assigns) do
    ~H"""
    <div class="absolute inset-y-0 left-0 flex items-center md:hidden">
      <button
        phx-click-away={hide_mobile_menu()}
        phx-click={toggle_mobile_menu()}
        type="button"
        class="inline-flex items-center justify-center rounded-md p-2 text-neutral-400 hover:bg-neutral-800 hover:text-neutral-50 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-rose-500 transition-colors"
        aria-controls="mobile-menu"
        aria-expanded="false"
      >
        <span class="sr-only">Open main menu</span>
        <span id="mobile_menu_is_open_icon" class="hidden">
          <.icon name="hero-x-mark" class="h-6 w-6 stroke-current" />
        </span>
        <span id="mobile_menu_is_closed_icon" class="block">
          <.icon name="hero-bars-3-solid" class="h-6 w-6 stroke-current" />
        </span>
      </button>
    </div>
    """
  end

  defp main_menu_links(assigns) do
    ~H"""
    <div class="flex flex-1 items-center justify-center md:items-stretch md:justify-start">
      <.logo />
      <div class="hidden md:ml-8 md:flex md:items-center">
        <div class="flex space-x-1">
          <.main_menu_link link_text="Events" href={~p"/"} />
          <.main_menu_link link_text="Venues" href={~p"/venues"} />
          <.main_menu_link link_text="About" href={~p"/contact"} />
          <.when_admin current_user={@current_user}>
            <.main_menu_link link_text="Submitted" href={~p"/submitted_events"} />
          </.when_admin>
        </div>
      </div>
    </div>
    """
  end

  defp mobile_menu(assigns) do
    ~H"""
    <div class="hidden md:hidden" id="mobile-menu">
      <div class="space-y-1 px-4 pt-2 pb-4 border-t border-neutral-800">
        <.mobile_menu_link link_text="Events" href={~p"/"} />
        <.mobile_menu_link link_text="Venues" href={~p"/venues"} />
        <.mobile_menu_link link_text="About" href={~p"/contact"} />
        <.when_admin current_user={@current_user}>
          <.mobile_menu_link link_text="Submitted" href={~p"/submitted_events"} />
        </.when_admin>
        <div class="pt-3 mt-3 border-t border-neutral-800">
          <a
            href={~p"/events/new"}
            class="block w-full text-center bg-rose-500 hover:bg-rose-400 text-neutral-950 font-semibold text-sm px-4 py-2.5 rounded-lg transition-colors"
          >
            + Submit Event
          </a>
        </div>
        <.when_admin current_user={@current_user}>
          <div class="pt-2">
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="text-sm text-rose-400 font-semibold hover:text-rose-300"
            >
              Log out
            </.link>
          </div>
        </.when_admin>
      </div>
    </div>
    """
  end

  defp logo(assigns) do
    ~H"""
    <div class="flex flex-shrink-0 items-center">
      <a
        href="/"
        class="text-2xl font-display font-bold tracking-tight text-neutral-50 hover:text-rose-400 transition-colors"
      >
        TML
      </a>
    </div>
    """
  end

  defp last_updated_label(assigns) do
    ~H"""
    <div class="text-xs text-neutral-500 font-mono flex items-center gap-2">
      <span>Updated {MusicListings.data_last_updated_on()}</span>
    </div>
    """
  end

  attr :link_text, :string, required: true
  attr :href, :string, required: true
  attr :rest, :global, include: ~w(method)

  defp mobile_menu_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class="text-neutral-400 hover:text-neutral-50 hover:bg-neutral-800 block px-3 py-2.5 rounded-lg text-base font-medium transition-colors"
      {@rest}
    >
      {@link_text}
    </.link>
    """
  end

  attr :link_text, :string, required: true
  attr :href, :string, required: true

  defp main_menu_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="text-sm font-medium uppercase tracking-wider text-neutral-400 hover:text-neutral-50 px-3 py-2 rounded-lg transition-colors"
    >
      {@link_text}
    </a>
    """
  end

  defp toggle_mobile_menu(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#mobile-menu", in: "ease-out duration-100", out: "ease-in duration-75")
    |> JS.toggle(to: "#mobile_menu_is_closed_icon")
    |> JS.toggle(to: "#mobile_menu_is_open_icon")
  end

  defp hide_mobile_menu(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-menu", transition: "ease-in duration-75")
    |> JS.hide(to: "#mobile_menu_is_open_icon")
    |> JS.show(to: "#mobile_menu_is_closed_icon")
  end
end
