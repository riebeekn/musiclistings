defmodule MusicListingsWeb.VenueLive.New do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      changeset(:new, %{
        city: "Toronto",
        province: "Ontario",
        country: "Canada",
        parser_module_name: "n/a",
        pull_events?: false
      })

    socket
    |> assign(page_title: "Submit an Event", form: to_form(changeset, as: :venue))
    |> ok()
  end

  @impl true
  def handle_event(
        "save",
        %{"venue" => venue_params},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    with {:ok, attrs} <- validate(:new, venue_params),
         {:ok, _venue} <- MusicListings.create_venue(current_user, attrs) do
      socket
      |> put_flash(
        :info,
        "Venue created."
      )
      |> push_navigate(to: ~p"/venues")
      |> noreply()
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(form: to_form(changeset, as: :venue))
        |> noreply()
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    socket
    |> push_navigate(to: ~p"/venues")
    |> noreply()
  end

  defparams :new do
    required(:name, :string)
    required(:street, :string)
    required(:city, :string)
    required(:province, :string)
    required(:country, :string)
    required(:postal_code, :string)
    required(:website, :string)
    required(:google_map_url, :string)
    required(:parser_module_name, :string)
    required(:pull_events?, :boolean)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header header="New Venue" />

    <.simple_form for={@form} id="venue-form" phx-submit="save">
      <.input field={@form[:name]} type="text" label="Venue name" />
      <.input field={@form[:street]} type="text" label="Street" />
      <.input field={@form[:city]} type="text" label="City" />
      <.input field={@form[:province]} type="text" label="Province" />
      <.input field={@form[:country]} type="text" label="Country" />
      <.input field={@form[:postal_code]} type="text" label="Postal Code" />
      <.input field={@form[:website]} type="text" label="Website" />
      <.input field={@form[:google_map_url]} type="text" label="Google Map URL" />
      <.input field={@form[:parser_module_name]} type="text" label="Parser Module Name" />
      <.input field={@form[:pull_events?]} type="select" options={[true, false]} label="Pull Events" />

      <:actions>
        <.button phx-click="cancel" type="button">Cancel</.button>
        <.submit_button phx-disable-with="Submitting...">Submit</.submit_button>
      </:actions>
    </.simple_form>
    """
  end
end
