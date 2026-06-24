defmodule MusicListingsWeb.SubmittedEventLive.Edit do
  use MusicListingsWeb, :live_view
  use Goal

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Price
  alias MusicListings.Venues

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{current_user: current_user}} = socket) do
    with {:ok, %{id: id}} <- validate(:show, params),
         {:ok, submitted_event} <- MusicListings.fetch_submitted_event(current_user, id) do
      form_params = %{
        title: submitted_event.title,
        venue: submitted_event.venue,
        date: submitted_event.date,
        time: submitted_event.time,
        price: submitted_event.price,
        url: submitted_event.url
      }

      socket
      |> assign(:page_title, "Edit Submission")
      |> assign(:submitted_event, submitted_event)
      |> assign(:form, to_form(changeset(:edit, form_params), as: :submitted_event))
      |> assign_hints(submitted_event.venue, submitted_event.time, submitted_event.price)
      |> noreply()
    else
      {:error, :not_allowed} ->
        socket
        |> push_navigate(to: ~p"/events")
        |> noreply()

      _error ->
        socket
        |> put_flash(:error, "Submitted event not found")
        |> push_navigate(to: ~p"/submitted_events")
        |> noreply()
    end
  end

  @impl true
  def handle_event("validate", %{"submitted_event" => params}, socket) do
    changeset =
      :edit
      |> changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(:form, to_form(changeset, as: :submitted_event))
    |> assign_hints(params["venue"], params["time"], params["price"])
    |> noreply()
  end

  @impl true
  def handle_event(
        "save",
        %{"submitted_event" => params},
        %{assigns: %{current_user: current_user, submitted_event: submitted_event}} = socket
      ) do
    with {:ok, attrs} <- validate(:edit, params),
         {:ok, _updated} <-
           MusicListings.update_submitted_event(current_user, submitted_event.id, attrs) do
      socket
      |> put_flash(:info, "Submission updated")
      |> push_navigate(to: ~p"/submitted_events")
      |> noreply()
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:form, to_form(changeset, as: :submitted_event))
        |> assign_hints(params["venue"], params["time"], params["price"])
        |> noreply()

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Could not update submission")
        |> noreply()
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    socket
    |> push_navigate(to: ~p"/submitted_events")
    |> noreply()
  end

  defp assign_hints(socket, venue, time, price) do
    socket
    |> assign(:venue_hint, venue_hint(venue))
    |> assign(:time_hint, time_hint(time))
    |> assign(:price_hint, price_hint(price))
  end

  defp venue_hint(venue) when venue in [nil, ""], do: nil

  defp venue_hint(venue) do
    case Venues.fetch_venue_by_name(venue) do
      {:ok, found} -> {:ok, "✓ Matches '#{found.name}'"}
      {:error, _reason} -> {:warn, "⚠ No venue matches — approval will fail"}
    end
  end

  defp time_hint(time) when time in [nil, ""], do: nil

  defp time_hint(time) do
    case ParseHelpers.build_time_from_time_string(time) do
      {:ok, parsed} -> {:ok, "→ Parses to #{Calendar.strftime(parsed, "%H:%M")}"}
      {:error, _reason} -> {:warn, "⚠ Couldn't parse — time will be left blank on approval"}
    end
  end

  defp price_hint(price) when price in [nil, ""], do: nil

  defp price_hint(price) do
    parsed = parse_price(price)

    case parsed.format do
      :unknown -> {:warn, "⚠ Couldn't parse — price will be Unknown on approval"}
      _format -> {:ok, "→ #{format_price_hint(parsed)}"}
    end
  end

  defp parse_price(price) do
    Price.new(price)
  rescue
    _parse_error -> Price.unknown()
  end

  defp format_price_hint(%Price{format: :free}), do: "Free"
  defp format_price_hint(%Price{format: :pwyc}), do: "Pay what you can"
  defp format_price_hint(%Price{format: :fixed, lo: lo}), do: "$#{lo}"
  defp format_price_hint(%Price{format: :variable, lo: lo}), do: "$#{lo}+"
  defp format_price_hint(%Price{format: :range, lo: lo, hi: hi}), do: "$#{lo} – $#{hi}"

  defparams :show do
    required(:id, :integer, min: 1)
  end

  defparams :edit do
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
    <div class="max-w-xl mx-auto">
      <.page_header header="Edit Submission" />

      <.simple_form
        for={@form}
        id="submitted-event-form"
        phx-change="validate"
        phx-submit="save"
        class="mt-6"
      >
        <.input field={@form[:title]} type="text" label="Event Title" />
        <.input field={@form[:venue]} type="text" label="Venue" />
        <.field_hint hint={@venue_hint} />
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:time]} type="text" label="Time (optional)" />
        <.field_hint hint={@time_hint} />
        <.input field={@form[:price]} type="text" label="Price (optional)" />
        <.field_hint hint={@price_hint} />
        <.input field={@form[:url]} type="text" label="URL (optional)" />
        <:actions>
          <.button type="button" phx-click="cancel">Cancel</.button>
          <.submit_button phx-disable-with="Saving...">Save</.submit_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :hint, :any, default: nil

  defp field_hint(assigns) do
    ~H"""
    <p :if={@hint} class={["-mt-3 text-xs", hint_class(@hint)]}>{elem(@hint, 1)}</p>
    """
  end

  defp hint_class({:ok, _message}), do: "text-spotlight"
  defp hint_class({:warn, _message}), do: "text-ember"
end
