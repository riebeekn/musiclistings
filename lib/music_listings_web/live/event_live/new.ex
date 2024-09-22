defmodule MusicListingsWeb.EventLive.New do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    changeset = changeset(:new, %{})
    socket = assign(socket, :form, to_form(changeset, as: :event))

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"event" => params}, socket) do
    with {:ok, attrs} <- validate(:new, params),
         {:ok, _event} <- MusicListings.submit_event(attrs) do
      {:noreply,
       socket
       |> put_flash(
         :info,
         "Thank you for submitting your event! We’ll review the details, and once approved (usually within 12 hours), your event will be live on the site."
       )
       |> push_navigate(to: ~p"/events")}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :event))}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/events")}
  end

  defparams :new do
    required(:title, :string)
    required(:venue, :string)
    required(:date, :date)
    optional(:time, :string)
    optional(:price, :string)
    optional(:url, :string)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header
      header="Submit Your Event"
      description="Share the details of your event with us using the form below."
    />

    <.simple_form for={@form} id="event-form" phx-submit="save">
      <.input field={@form[:title]} type="text" label="Event Title" />
      <.input field={@form[:venue]} type="text" label="Venue" />
      <.input field={@form[:date]} type="date" label="Date" />
      <.input field={@form[:time]} type="text" label="Time (optional)" />
      <.input field={@form[:price]} type="text" label="Price (optional)" />
      <.input field={@form[:url]} type="text" label="URL (optional)" />
      <:actions>
        <.button phx-click="cancel" type="button">Cancel</.button>
        <.submit_button phx-disable-with="Submitting...">Submit</.submit_button>
      </:actions>
    </.simple_form>
    """
  end
end
