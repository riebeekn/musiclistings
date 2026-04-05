defmodule MusicListingsWeb.ContactLive.New do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListings.Emails.ContactUs
  alias MusicListings.Mailer

  @impl true
  def mount(_params, _session, socket) do
    changeset = changeset(:new, %{})
    socket = assign(socket, page_title: "Contact", form: to_form(changeset, as: :contact))

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"contact" => contact_params} = params, socket) do
    with {:ok, _ts_return} <- turnstile_verification(params),
         {:ok, attrs} <- validate(:new, contact_params),
         email <- ContactUs.new_email(attrs),
         {:ok, _mailer_result} <- Mailer.deliver(email) do
      socket
      |> put_flash(
        :info,
        "Thank you for contacting us, we'll get back to you asap!"
      )
      |> push_navigate(to: ~p"/events")
      |> noreply()
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(form: to_form(changeset, as: :contact))
        |> Turnstile.refresh()
        |> noreply()

      {:error, _error} ->
        socket
        |> put_flash(:error, "Please try submitting again")
        |> Turnstile.refresh()
        |> noreply()
    end
  end

  defp turnstile_verification(params) do
    if Application.get_env(:music_listings, :env) == :test do
      {:ok, :success}
    else
      Turnstile.verify(params)
    end
  end

  defparams :new do
    required(:name, :string)
    required(:email, :string)
    required(:subject, :string)
    required(:message, :string)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <div class="mb-12 sm:mb-16">
        <h1 class="font-display text-4xl sm:text-5xl font-bold tracking-tight text-neutral-50">
          About
        </h1>
        <p class="mt-4 text-lg text-neutral-400 max-w-2xl leading-relaxed">
          Toronto Music Listings came about as a fun side project to help keep track of
          live shows happening in Toronto.
        </p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-16">
        <div class="bg-neutral-900 rounded-xl border border-neutral-800 p-6">
          <div class="rounded-lg bg-rose-500/10 p-2.5 w-fit mb-4">
            <MusicListingsWeb.CoreComponents.icon
              name="hero-musical-note"
              class="size-5 text-rose-400"
            />
          </div>
          <h3 class="text-sm font-semibold text-neutral-50 mb-1">Daily updates</h3>
          <p class="text-sm text-neutral-500 leading-relaxed">
            Events are refreshed daily so you always see what's coming up.
          </p>
        </div>
        <div class="bg-neutral-900 rounded-xl border border-neutral-800 p-6">
          <div class="rounded-lg bg-rose-500/10 p-2.5 w-fit mb-4">
            <MusicListingsWeb.CoreComponents.icon
              name="hero-building-storefront"
              class="size-5 text-rose-400"
            />
          </div>
          <h3 class="text-sm font-semibold text-neutral-50 mb-1">Dozens of venues</h3>
          <p class="text-sm text-neutral-500 leading-relaxed">
            From small clubs to concert halls, we track shows across the city.
          </p>
        </div>
        <div class="bg-neutral-900 rounded-xl border border-neutral-800 p-6">
          <div class="rounded-lg bg-rose-500/10 p-2.5 w-fit mb-4">
            <MusicListingsWeb.CoreComponents.icon
              name="hero-code-bracket"
              class="size-5 text-rose-400"
            />
          </div>
          <h3 class="text-sm font-semibold text-neutral-50 mb-1">Open source</h3>
          <p class="text-sm text-neutral-500 leading-relaxed">
            Curious how it works? Check out the <a
              href="https://github.com/riebeekn/musiclistings"
              class="text-rose-400 hover:text-rose-300"
              target="_blank"
            >code on GitHub</a>.
          </p>
        </div>
      </div>

      <div class="flex items-center gap-4 mb-10">
        <h2 class="font-display text-2xl sm:text-3xl font-bold text-neutral-50 whitespace-nowrap">
          Get in touch
        </h2>
        <div class="flex-1 h-px bg-neutral-800"></div>
      </div>

      <p class="text-sm text-neutral-400 mb-8 max-w-xl">
        Have a question, suggestion, or want to share an upcoming event?
        Drop a message and I'll get back to you as soon as possible.
      </p>

      <div class="max-w-xl">
        <.simple_form
          for={@form}
          id="contact-form"
          phx-submit="save"
          action_layout="justify-end"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-6">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:email]} type="email" label="Email" />
          </div>
          <.input field={@form[:subject]} type="text" label="Subject" />
          <.input field={@form[:message]} type="textarea" label="Message" />
          <div class="flex justify-end">
            <Turnstile.widget theme="dark" />
          </div>
          <:actions>
            <.submit_button phx-disable-with="Sending...">Send message</.submit_button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
