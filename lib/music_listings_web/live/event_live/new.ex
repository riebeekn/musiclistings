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
            <div class="flex items-start gap-3">
              <div class="mt-1 flex-shrink-0 rounded-lg bg-rose-500/10 p-2">
                <MusicListingsWeb.CoreComponents.icon
                  name="hero-clock"
                  class="size-5 text-rose-400"
                />
              </div>
              <div>
                <p class="text-sm font-semibold text-neutral-50">Quick review</p>
                <p class="text-sm text-neutral-400">
                  Submissions are usually reviewed and approved within 24 hours.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <div class="mt-1 flex-shrink-0 rounded-lg bg-rose-500/10 p-2">
                <MusicListingsWeb.CoreComponents.icon
                  name="hero-musical-note"
                  class="size-5 text-rose-400"
                />
              </div>
              <div>
                <p class="text-sm font-semibold text-neutral-50">All genres welcome</p>
                <p class="text-sm text-neutral-400">
                  From jazz to punk, electronic to folk - if it's live music in Toronto, we want to list it.
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <div class="mt-1 flex-shrink-0 rounded-lg bg-rose-500/10 p-2">
                <MusicListingsWeb.CoreComponents.icon
                  name="hero-information-circle"
                  class="size-5 text-rose-400"
                />
              </div>
              <div>
                <p class="text-sm font-semibold text-neutral-50">Just the basics</p>
                <p class="text-sm text-neutral-400">
                  Only the event title, venue, and date are required. Everything else is optional.
                </p>
              </div>
            </div>
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
            <.button
              phx-click="cancel"
              type="button"
              class="border border-neutral-700 hover:bg-neutral-800 transition-colors"
            >
              Cancel
            </.button>
            <.submit_button phx-disable-with="Submitting...">Submit Event</.submit_button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
