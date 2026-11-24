defmodule MusicListingsWeb.EventLive.New do
  use MusicListingsWeb, :live_view
  use Goal

  @impl true
  def mount(_params, _session, socket) do
    changeset = changeset(:new, %{})

    socket
    |> assign(
      page_title: "Submit an Event",
      form: to_form(changeset, as: :event),
      show_turnstile: true,
      noindex: true
    )
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
        "Thank you for submitting your event! We'll review the details, and once approved (usually within 24 hours), your event will be live on the site."
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
    <div class="relative isolate">
      <div class="mx-auto grid max-w-7xl grid-cols-1 lg:grid-cols-2">
        <.cta header="Submit Your Event">
          <p>
            Know about an upcoming show that's not listed? Help us keep Toronto's music scene covered.
          </p>
          <div class="mt-4 space-y-4">
            <.submission_tip icon="hero-clock" title="Quick review">
              Submissions are usually reviewed and approved within 24 hours.
            </.submission_tip>
            <.submission_tip icon="hero-musical-note" title="All genres welcome">
              From jazz to punk, electronic to folk - if it's live music in Toronto, we want to list it.
            </.submission_tip>
            <.submission_tip icon="hero-information-circle" title="Just the basics">
              Only the event title, venue, and date are required. Everything else is optional.
            </.submission_tip>
          </div>
        </.cta>

        <.simple_form
          for={@form}
          id="event-form"
          phx-submit="save"
          class="px-6 pb-12 lg:px-8 lg:py-36"
        >
          <.input field={@form[:title]} type="text" label="Event Title" />
          <.input field={@form[:venue]} type="text" label="Venue" />
          <.input field={@form[:date]} type="date" label="Date" />
          <.input field={@form[:time]} type="text" label="Time (optional)" />
          <.input field={@form[:price]} type="text" label="Price (optional)" />
          <.input field={@form[:url]} type="text" label="URL (optional)" />
          <div class="flex justify-end">
            <Turnstile.widget theme="dark" />
          </div>
          <:actions>
            <.button type="button" phx-click="cancel">Cancel</.button>
            <.submit_button phx-disable-with="Submitting...">Submit Event</.submit_button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  attr :header, :string, required: true
  slot :inner_block, required: true

  defp cta(assigns) do
    ~H"""
    <div class="relative px-6 pt-10 pb-8 lg:static lg:px-8 lg:py-32">
      <div class="mx-auto max-w-xl lg:mx-0 lg:max-w-lg">
        <.kicker>Got a show?</.kicker>
        <h1 class="headline mt-4 text-6xl text-paper sm:text-7xl">
          {@header}
        </h1>
        <div class="mt-6 space-y-6 text-base leading-relaxed text-paper-dim lg:text-lg">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp submission_tip(assigns) do
    ~H"""
    <div class="flex items-start gap-3">
      <div class="mt-1 shrink-0 rounded-lg bg-spotlight/10 p-2">
        <.icon name={@icon} class="size-5 text-spotlight" />
      </div>
      <div>
        <p class="text-sm font-semibold text-paper">{@title}</p>
        <p class="text-sm text-paper-dim">
          {render_slot(@inner_block)}
        </p>
      </div>
    </div>
    """
  end
end
