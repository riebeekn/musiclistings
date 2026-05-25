defmodule MusicListingsWeb.ContactLive.New do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListings.Emails.ContactUs
  alias MusicListings.Mailer

  @impl true
  def mount(_params, _session, socket) do
    changeset = changeset(:new, %{})

    socket =
      assign(socket,
        page_title: "Contact",
        form: to_form(changeset, as: :contact),
        show_turnstile: true
      )

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
      <div class="mb-14 border-b border-hairline pb-10">
        <p class="kicker flex items-center gap-2">
          <span class="inline-block h-2 w-8 bg-spotlight"></span> Toronto Music Listings
        </p>
        <h1 class="headline mt-4 text-6xl text-paper sm:text-7xl">
          A field guide<br />to the city's stages
        </h1>
        <p class="mt-5 max-w-2xl text-base leading-relaxed text-paper-dim sm:text-lg">
          Toronto Music Listings came about as a fun side project to help keep track of
          live shows happening in Toronto.
        </p>
      </div>

      <div class="mb-16 grid grid-cols-1 border-t border-hairline sm:grid-cols-3">
        <.about_card icon="hero-musical-note" title="Daily updates">
          Events are refreshed daily so you always see what's coming up.
        </.about_card>
        <.about_card icon="hero-building-storefront" title="Dozens of venues">
          From small clubs to concert halls, we track shows across the city.
        </.about_card>
        <.about_card icon="hero-code-bracket" title="Open source">
          Curious how it works? Check out the <a
            href="https://github.com/riebeekn/musiclistings"
            class="text-spotlight underline-offset-2 hover:underline"
            target="_blank"
            rel="noopener"
          >code on GitHub</a>.
        </.about_card>
      </div>

      <div class="flex items-end gap-5 mb-10">
        <h2 class="headline text-4xl sm:text-5xl text-paper whitespace-nowrap">
          Get in touch
        </h2>
        <div class="mb-2.5 flex-1 h-px bg-hairline"></div>
      </div>

      <p class="text-sm text-paper-dim mb-8 max-w-xl">
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

  attr :icon, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp about_card(assigns) do
    ~H"""
    <div class="border-b border-hairline px-1 py-7 sm:px-6 sm:[&:not(:nth-child(3n))]:border-r">
      <div class="mb-4 grid size-9 place-items-center bg-spotlight">
        <MusicListingsWeb.CoreComponents.icon name={@icon} class="size-5 text-ink" />
      </div>
      <h3 class="font-display text-xl font-bold text-paper">{@title}</h3>
      <p class="mt-1 text-sm leading-relaxed text-paper-dim">
        {render_slot(@inner_block)}
      </p>
    </div>
    """
  end
end
