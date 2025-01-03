defmodule MusicListingsWeb.EventLive.New do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    changeset = changeset(:new, %{})

    socket
    |> assign(page_title: "Submit an Event", form: to_form(changeset, as: :event))
    |> ok()
  end

  @impl true
  def handle_event("save", %{"event" => event_params} = params, socket) do
    with {:ok, _ts_return} <- turnstile_verification(params),
         {:ok, attrs} <- validate(:new, event_params),
         {:ok, _event} <- MusicListings.submit_event(attrs) do
      socket
      |> put_flash(
        :info,
        "Thank you for submitting your event! We’ll review the details, and once approved (usually within 24 hours), your event will be live on the site."
      )
      |> push_navigate(to: ~p"/events")
      |> noreply()
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(form: to_form(changeset, as: :event))
        |> Turnstile.refresh()
        |> noreply()

      {:error, _error} ->
        socket
        |> put_flash(:error, "Please try submitting again")
        |> Turnstile.refresh()
        |> noreply()
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    socket
    |> push_navigate(to: ~p"/events")
    |> noreply()
  end

  defp turnstile_verification(params) do
    if Application.get_env(:music_listings, :env) == :test do
      {:ok, :success}
    else
      Turnstile.verify(params)
    end
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
      description="Share the details of your event using the form below."
    />

    <.simple_form for={@form} id="event-form" phx-submit="save">
      <.input field={@form[:title]} type="text" label="Event Title" />
      <.input field={@form[:venue]} type="text" label="Venue" />
      <.input field={@form[:date]} type="date" label="Date" />
      <.input field={@form[:time]} type="text" label="Time (optional)" />
      <.input field={@form[:price]} type="text" label="Price (optional)" />
      <.input field={@form[:url]} type="text" label="URL (optional)" />
      <div class="text-end">
        <Turnstile.widget theme="dark" />
      </div>
      <:actions>
        <.button phx-click="cancel" type="button">Cancel</.button>
        <.submit_button phx-disable-with="Submitting...">Submit</.submit_button>
      </:actions>
    </.simple_form>
    """
  end
end
