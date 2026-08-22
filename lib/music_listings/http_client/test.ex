defmodule MusicListings.HttpClient.Test do
  @moduledoc """
  Test HttpClient implementation that serves fixture files for known
  URL patterns and returns errors for everything else. This allows
  parsers that fetch detail pages to exercise their actual parsing
  logic in tests rather than only testing fallback paths.
  """
  @behaviour MusicListings.HttpClient

  alias MusicListings.HttpClient.Response

  @fixture_base "test/data"

  @impl true
  def get(url, _headers \\ [], _opts \\ []) do
    case fixture_for_url(url) do
      {:ok, body} -> {:ok, Response.new(200, body)}
      :error -> {:error, :test_env}
    end
  end

  @impl true
  def post(_url, _body, _headers), do: {:error, :test_env}

  defp fixture_for_url(url) do
    url
    |> match_fixture()
    |> read_fixture()
  end

  defp match_fixture(url) do
    Enum.find_value(fixtures(), fn {pattern, fixture_path} ->
      if String.contains?(url, pattern), do: fixture_path
    end)
  end

  defp read_fixture(nil), do: :error

  defp read_fixture(fixture_path) do
    @fixture_base
    |> Path.join(fixture_path)
    |> File.read()
    |> case do
      {:ok, body} -> {:ok, body}
      {:error, _reason} -> :error
    end
  end

  defp fixtures do
    [
      # Roy Thomson Hall — list endpoint must match before singular instance endpoint
      {"roythomsonhall.mhrth.com/api/attendable/v1/instances/?child_of",
       "roy_thomson_hall/instances.json"},
      {"roythomsonhall.mhrth.com/api/attendable/v1/instances/", "roy_thomson_hall/instance.json"},
      {"roythomsonhall.mhrth.com/tickets/", "roy_thomson_hall/detail.html"},
      # Massey Hall — per-instance routes match before the generic list pattern
      {"masseyhall.mhrth.com/api/attendable/v1/instances/?child_of",
       "massey_hall/instances.json"},
      {"masseyhall.mhrth.com/api/attendable/v1/instances/4261", "massey_hall/instance_4261.json"},
      {"masseyhall.mhrth.com/api/attendable/v1/instances/4294", "massey_hall/instance_4294.json"},
      {"masseyhall.mhrth.com/tickets/", "massey_hall/detail.html"},
      # TD Music Hall
      {"tdmusichall.mhrth.com/api/attendable/v1/instances/?child_of",
       "td_music_hall/instances.json"},
      {"tdmusichall.mhrth.com/api/attendable/v1/instances/", "td_music_hall/instance.json"},
      {"tdmusichall.mhrth.com/tickets/", "td_music_hall/detail.html"},
      # Drake Underground - the event page is the only place the show date
      # appears, so each fixture stands for a different shape of that page.
      # Deliberately no catch-all: an event with no fixture exercises the
      # "couldn't reach the page" path.
      {"thedrake.ca/event/3809/", "drake_underground/detail.html"},
      {"thedrake.ca/event/i-feel-free", "drake_underground/detail_image_date_only.html"},
      {"thedrake.ca/event/with-love-ramaan", "drake_underground/detail_stale_listing.html"},
      {"thedrake.ca/event/bo-staloch", "drake_underground/detail_implausible_image_date.html"},
      {"thedrake.ca/event/stacey-ryan", "drake_underground/detail_no_date.html"},
      # The Bowl at Sobeys Stadium - each show has its own page holding the
      # ticket vendor link and the show time.  Only the shows the tests care
      # about have a fixture; the rest are left unmatched on purpose so the
      # parser's "no show page" fallbacks are exercised too.
      {"liveatthebowl.com/howard-jones", "bowl/howard-jones.html"},
      {"liveatthebowl.com/heroes-a-video-game-symphony",
       "bowl/heroes-a-video-game-symphony.html"},
      {"liveatthebowl.com/interpol", "bowl/interpol.html"},
      # The Great Hall - the calendar carries no vendor link at all, so each
      # fixture stands for a different shape of an event's own page.  As above,
      # the calendar's other events are left unmatched on purpose so the
      # "couldn't reach the page" path is exercised too.
      {"thegreathall.ca/event/brass-camel-featuring-a-short-walk-to-pluto",
       "great_hall/detail.html"},
      {"thegreathall.ca/event/casey-mq", "great_hall/detail_no_button.html"},
      {"thegreathall.ca/event/nada-surf", "great_hall/detail_link_protect.html"},
      # El Mocambo - only the events that leave the calendar's website icon
      # empty need their own page fetched, so these stand for the two shapes
      # that page comes in.  The rest are left unmatched on purpose.
      {"elmocambo.com/event/sousapalooza-day-1", "el_mocambo/detail.html"},
      {"elmocambo.com/event/high-flyer-release-show", "el_mocambo/detail_no_ticket_link.html"},
      # The Phoenix - the index carries neither the vendor link nor the price,
      # so each fixture stands for a different shape of an event's own page.
      # ladytron is deliberately left unmatched to exercise the "couldn't reach
      # the page" fallbacks.
      {"thephoenixconcerttheatre.com/events/event/tinariwen", "phoenix/detail.html"},
      {"thephoenixconcerttheatre.com/events/event/the-volunteers",
       "phoenix/detail_and_up_price.html"},
      {"thephoenixconcerttheatre.com/events/event/homixide-gang", "phoenix/detail_no_price.html"},
      # BSMT 254 - the listing carries no ticket link, start time or price, so
      # each fixture stands for a different shape of an event's own page.  As
      # above, the listing's other events are left unmatched on purpose so the
      # "couldn't reach the page" fallbacks are exercised too.
      # HISTORY - a run of shows lists no ticket link of its own, so each night's
      # link is read off the event's own page.  Deliberately no catch-all: the
      # listing's single date events must not fetch anything.
      {"historytoronto.com/events/detail/isoxo", "history/detail_showings.html"},
      {"bsmt254.com/event/rhythm-n-bingo", "bsmt254/detail.html"},
      {"bsmt254.com/event/not-a-bbq-x-hit-play", "bsmt254/detail_no_ticket_link.html"},
      {"bsmt254.com/event/project-nowhere-night-1", "bsmt254/detail_pwyc_price.html"},
      {"bsmt254.com/event/project-nowhere-night-2", "bsmt254/detail_prose_price.html"},
      # Story — token endpoint is fetched first, then the events API is called
      # with the token it yields.
      {"storytoronto.ca/_api/v1/access-tokens", "story/access_tokens.json"},
      {"storytoronto.ca/_api/wix-one-events-server", "story/index.json"},
      # CONTXT by Trane — the venue's public Google Calendar
      {"googleapis.com/calendar/v3/calendars/027559b2", "contxt_by_trane/index.json"},
      # TicketNetwork affiliate catalog — paged, so each page has its own fixture
      {"api.impact.com/Mediapartners/test_account_sid/Catalogs/1872/Items?Query=Category+%3D+%27CONCERTS%27+AND+Gtin+%3D+%27Toronto%27&Page=1",
       "ticket_network/page_1.json"},
      {"api.impact.com/Mediapartners/test_account_sid/Catalogs/1872/Items?Query=Category+%3D+%27CONCERTS%27+AND+Gtin+%3D+%27Toronto%27&Page=2",
       "ticket_network/page_2.json"}
    ]
  end
end
