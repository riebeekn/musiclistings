defmodule MusicListingsWeb.FeatureFlagLive.Index do
  use MusicListingsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    if connected?(socket) do
      case MusicListings.list_feature_flags(current_user) do
        {:ok, flags} ->
          socket
          |> assign(:flags, flags)
          |> assign(:loading, false)
          |> noreply()

        {:error, :not_allowed} ->
          socket
          |> push_navigate(to: ~p"/events")
          |> noreply()
      end
    else
      socket
      |> assign(:flags, [])
      |> assign(:loading, true)
      |> noreply()
    end
  end

  @impl true
  def handle_event(
        "toggle-flag",
        %{"name" => name, "enabled" => enabled},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    flag_name = String.to_existing_atom(name)
    currently_enabled? = enabled == "true"

    current_user
    |> MusicListings.set_feature_flag(flag_name, !currently_enabled?)
    |> case do
      {:ok, _enabled?} ->
        {:ok, flags} = MusicListings.list_feature_flags(current_user)

        socket
        |> assign(:flags, flags)
        |> noreply()

      {:error, :not_allowed} ->
        socket
        |> put_flash(:error, "Auth error")
        |> noreply()
    end
  end

  defp humanize_flag_name(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.loading_indicator :if={@loading} />

    <.page_header
      header="Feature Flags"
      description="Toggle global feature flags on or off."
    />

    <div class="mt-4 divide-y divide-hairline border-y border-hairline">
      <div
        :for={flag <- @flags}
        id={"flag-#{flag.name}"}
        class="flex items-center justify-between gap-4 py-4"
      >
        <div>
          <p class="text-paper">{humanize_flag_name(flag.name)}</p>
          <p class="font-mono text-xs text-paper-dim">{flag.name}</p>
        </div>

        <%= if flag.enabled? do %>
          <.submit_button
            phx-click="toggle-flag"
            phx-value-name={flag.name}
            phx-value-enabled="true"
          >
            On
          </.submit_button>
        <% else %>
          <.button
            phx-click="toggle-flag"
            phx-value-name={flag.name}
            phx-value-enabled="false"
          >
            Off
          </.button>
        <% end %>
      </div>

      <p :if={@flags == [] and not @loading} class="py-4 text-sm text-paper-dim">
        No feature flags found.
      </p>
    </div>
    """
  end
end
