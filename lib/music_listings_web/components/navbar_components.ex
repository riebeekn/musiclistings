defmodule MusicListingsWeb.NavbarComponents do
  @moduledoc """
  Navbar related components
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MusicListingsWeb.Endpoint,
    router: MusicListingsWeb.Router,
    statics: MusicListingsWeb.static_paths()

  alias Phoenix.LiveView.JS

  @doc """
  Renders the navbar

  ## Example

  <.navbar />
  """
  def navbar(assigns) do
    ~H"""
    <nav class="border-zinc-700 border-b">
      <.main_menu />
      <.mobile_menu />
    </nav>
    """
  end

  defp main_menu(assigns) do
    ~H"""
    <div class="block sm:hidden flex flex-auto basis-full overflow-x-auto whitespace-nowrap border-b border-emerald-600 py-4 ">
      <div class="mx-auto flex items-center gap-4 px-4">
        <.last_updated_label />
      </div>
    </div>
    <div class="mx-auto max-w-7xl px-2 sm:px-6 lg:px-8">
      <div class="relative flex h-16 items-center justify-between">
        <.mobile_menu_button />
        <.main_menu_links />
        <div class="absolute inset-y-0 right-0 items-center sm:static sm:inset-auto sm:ml-6 hidden sm:block">
          <div class="relative ml-3">
            <.last_updated_label />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp mobile_menu_button(assigns) do
    ~H"""
    <div class="absolute inset-y-0 left-0 flex items-center sm:hidden">
      <!-- Mobile menu button-->
      <button
        phx-click-away={hide_mobile_menu()}
        phx-click={toggle_mobile_menu()}
        type="button"
        class="inline-flex items-center justify-center rounded-md p-2 text-zinc-400 hover:bg-zinc-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
        aria-controls="mobile-menu"
        aria-expanded="false"
      >
        <span class="sr-only">Open main menu</span>
        <!--
                Icon when menu is open.
              -->
        <span id="mobile_menu_is_open_icon" class="hidden">
          <MusicListingsWeb.CoreComponents.icon name="hero-x-mark" class="h-6 w-6 stroke-current" />
        </span>
        <!--
                Icon when menu is closed.
              -->
        <span id="mobile_menu_is_closed_icon" class="block">
          <MusicListingsWeb.CoreComponents.icon
            name="hero-bars-3-solid"
            class="h-6 w-6 stroke-current"
          />
        </span>
      </button>
    </div>
    """
  end

  defp main_menu_links(assigns) do
    ~H"""
    <div class="flex flex-1 items-center justify-center sm:items-stretch sm:justify-start">
      <.logo />
      <div class="hidden sm:ml-6 sm:block">
        <div class="flex space-x-4">
          <.main_menu_link link_text="Events" href={~p"/"} />
          <.main_menu_link link_text="Venues" href={~p"/venues"} />
          <!--
          <.main_menu_link link_text="Subscribe" href={~p"/venue"} />
          <.main_menu_link link_text="About" href="#" />
          -->
        </div>
      </div>
    </div>
    """
  end

  defp mobile_menu(assigns) do
    ~H"""
    <div class="hidden sm:hidden" id="mobile-menu">
      <div class="space-y-1 px-2 pt-2 pb-3">
        <.mobile_menu_link link_text="Events" href={~p"/"} />
        <.mobile_menu_link link_text="Venues" href={~p"/venues"} />
        <!--
        <.mobile_menu_link link_text="Subscribe" href={~p"/venue"} />
        <.mobile_menu_link link_text="About" href="#" />
        -->
      </div>
    </div>
    """
  end

  defp logo(assigns) do
    ~H"""
    <div class="flex flex-shrink-0 items-center">
      <a href="/" class="mr-2 text-zinc-200 font-semi-bold text-3xl font-lobster">TML</a>
    </div>
    """
  end

  defp last_updated_label(assigns) do
    ~H"""
    <div class="text-sm text-zinc-300 font-mono mx-auto flex items-center gap-4 px-4">
      <p>
        Last updated
      </p>
      <svg
        aria-hidden="true"
        viewBox="0 0 6 6"
        class="h-1.5 w-1.5 overflow-visible fill-current stroke-current"
      >
        <path d="M3 0L6 3L3 6L0 3Z" stroke-width="2" stroke-linejoin="round"></path>
      </svg>
      <p><%= MusicListings.data_last_updated_on() %></p>
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
      class="text-zinc-400 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
      {@rest}
    >
      <%= @link_text %>
    </.link>
    """
  end

  attr :link_text, :string, required: true
  attr :href, :string, required: true

  defp main_menu_link(assigns) do
    ~H"""
    <a href={@href} class="text-zinc-400 px-3 py-2 rounded-md text-xl font-semibold hover:text-white">
      <%= @link_text %>
    </a>
    """
  end

  defp toggle_mobile_menu(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#mobile-menu", in: "ease-out duration-100", out: "ease-in duration-75")
    |> JS.toggle(to: ["#mobile_menu_is_closed_icon", "#mobile_menu_is_open_icon"])
  end

  defp hide_mobile_menu(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-menu", transition: "ease-in duration-75")
    |> JS.hide(to: "#mobile_menu_is_open_icon")
    |> JS.show(to: "#mobile_menu_is_closed_icon")
  end
end
