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

  @ticker_phrase "Toronto Live Music ◆ Concerts ◆ Club Shows ◆ DIY ◆ Jazz ◆ Punk ◆ Electronic ◆ Folk ◆ Updated Daily ◆ "

  @doc """
  Renders the navbar

  ## Example

  <.navbar />
  """
  def navbar(assigns) do
    ~H"""
    <header class="sticky top-0 z-50">
      <.ticker />
      <nav class="bg-ink/85 backdrop-blur-xl border-b border-hairline">
        <.mobile_updated_banner current_user={@current_user} />
        <.main_menu current_user={@current_user} />
        <.mobile_menu current_user={@current_user} />
      </nav>
    </header>
    """
  end

  defp ticker(assigns) do
    assigns = assign(assigns, :phrase, String.duplicate(@ticker_phrase, 4))

    ~H"""
    <div class="overflow-hidden border-b border-hairline bg-spotlight text-ink">
      <div class="flex w-max animate-marquee will-change-transform">
        <span class="whitespace-nowrap py-1 font-mono text-[0.7rem] font-bold uppercase tracking-[0.2em]">
          {@phrase}
        </span>
        <span
          aria-hidden="true"
          class="whitespace-nowrap py-1 font-mono text-[0.7rem] font-bold uppercase tracking-[0.2em]"
        >
          {@phrase}
        </span>
      </div>
    </div>
    """
  end

  defp main_menu(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl px-5 sm:px-8 lg:px-10">
      <div class="relative flex h-16 items-center justify-between">
        <.mobile_menu_button />
        <.main_menu_links current_user={@current_user} />
        <div class="hidden md:flex items-center gap-5">
          <.live_label />
          <a
            href={~p"/events/new"}
            class="inline-flex h-8 items-center justify-center gap-x-1.5 rounded bg-spotlight px-3.5 font-mono text-xs font-medium uppercase tracking-widest text-ink transition-colors hover:bg-spotlight-deep"
          >
            Submit Event
          </a>
          <.when_admin current_user={@current_user}>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="kicker hover:text-spotlight transition-colors"
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
    <div class="block md:hidden border-b border-hairline py-2.5">
      <div class="mx-auto flex flex-col items-center px-4">
        <.live_label />
        <.when_admin current_user={@current_user}>
          <div class="mt-1">
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="kicker hover:text-spotlight"
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
        class="inline-flex items-center justify-center rounded-md p-2 text-paper-dim hover:bg-ink-3 hover:text-paper focus:outline-hidden focus:ring-2 focus:ring-inset focus:ring-spotlight transition-colors"
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
      <div class="space-y-1 px-4 pt-2 pb-4 border-t border-hairline">
        <.mobile_menu_link link_text="Events" href={~p"/"} />
        <.mobile_menu_link link_text="Venues" href={~p"/venues"} />
        <.mobile_menu_link link_text="About" href={~p"/contact"} />
        <.when_admin current_user={@current_user}>
          <.mobile_menu_link link_text="Submitted" href={~p"/submitted_events"} />
        </.when_admin>
        <div class="pt-3 mt-3 border-t border-hairline">
          <a
            href={~p"/events/new"}
            class="inline-flex h-9 w-full items-center justify-center gap-x-2 rounded bg-spotlight px-4 font-mono text-sm font-medium uppercase tracking-widest text-ink transition-colors hover:bg-spotlight-deep"
          >
            Submit Event
          </a>
        </div>
        <.when_admin current_user={@current_user}>
          <div class="pt-2">
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="kicker hover:text-spotlight"
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
    <a href="/" class="group flex shrink-0 items-center gap-2.5">
      <span class="grid size-8 place-items-center bg-spotlight font-display text-xl font-black leading-none text-ink">
        T
      </span>
      <span class="headline hidden text-xl text-paper transition-colors group-hover:text-spotlight sm:block">
        Toronto Music Listings
      </span>
    </a>
    """
  end

  defp live_label(assigns) do
    ~H"""
    <div class="kicker flex items-center gap-2">
      <span class="relative flex size-2">
        <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-spotlight opacity-70"></span>
        <span class="relative inline-flex size-2 rounded-full bg-spotlight"></span>
      </span>
      Updated {MusicListings.data_last_updated_on()}
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
      class="text-paper-dim hover:text-paper hover:bg-ink-3 block px-3 py-2.5 rounded-lg text-base font-medium transition-colors"
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
      class="kicker px-3 py-2 text-paper-dim hover:text-spotlight transition-colors"
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
