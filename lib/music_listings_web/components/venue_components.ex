defmodule MusicListingsWeb.VenueComponents do
  @moduledoc """
  Components shared by the venue pages.
  """

  use Phoenix.Component

  @doc """
  Renders an admin's switch for whether the nightly crawl pulls a venue's events.
  Clicking it sends `toggle-pull-events` with the venue's id and the new setting.

  ## Example

  <.pull_events_toggle venue={@venue} />
  """
  attr :venue, :map, required: true, doc: "anything with an `id` and `pull_events?`"

  def pull_events_toggle(assigns) do
    ~H"""
    <button
      type="button"
      id={"pull-events-#{@venue.id}"}
      role="switch"
      aria-checked={to_string(@venue.pull_events?)}
      phx-click="toggle-pull-events"
      phx-value-id={@venue.id}
      phx-value-pull-events={to_string(!@venue.pull_events?)}
      title={
        if @venue.pull_events?,
          do: "The nightly crawl pulls this venue's events. Click to stop.",
          else: "The nightly crawl skips this venue. Click to start pulling its events."
      }
      class="group/toggle inline-flex h-9 items-center gap-2.5 rounded px-2 text-sm text-paper-dim transition-colors hover:text-paper focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-spotlight/60"
    >
      <span class={[
        "relative inline-flex h-5 w-9 shrink-0 items-center rounded-full border transition-colors",
        if(@venue.pull_events?,
          do: "border-spotlight/40 bg-spotlight/15",
          else: "border-hairline bg-ink-3"
        )
      ]}>
        <span class={[
          "inline-block size-3.5 rounded-full transition-transform",
          if(@venue.pull_events?,
            do: "translate-x-[1.125rem] bg-spotlight",
            else: "translate-x-0.5 bg-paper-dim"
          )
        ]}></span>
      </span>
      {if @venue.pull_events?, do: "Pulling events", else: "Not pulling events"}
    </button>
    """
  end
end
