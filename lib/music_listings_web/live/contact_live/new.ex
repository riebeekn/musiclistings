defmodule MusicListingsWeb.ContactLive.New do
  use MusicListingsWeb, :live_view
  use Goal

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
         {:ok, email} <- Mailer.new(attrs.name, attrs.email, attrs.subject, attrs.message),
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

      {:error, _} ->
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
    <div class="relative isolate">
      <div class="mx-auto grid max-w-7xl grid-cols-1 lg:grid-cols-2">
        <.cta header="Get in touch">
          <p>
            We’d love to hear from you! Whether you have a question, suggestion, or want to share an upcoming event, we’re here for it!
          </p>
          <p>
            Drop us a message, and we’ll get back to you as soon as possible!
          </p>
        </.cta>

        <.simple_form
          for={@form}
          id="contact-form"
          phx-submit="save"
          action_layout="justify-start"
          class="px-6 pb-24 sm:pt-20 sm:pb-32 lg:px-8 lg:py-36"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:email]} type="email" label="Email" />
          <.input field={@form[:subject]} type="text" label="Subject" />
          <.input field={@form[:message]} type="textarea" label="Message" />
          <Turnstile.widget theme="dark" />
          <:actions>
            <.submit_button phx-disable-with="Sending...">Send message</.submit_button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
