defmodule MusicListings.Crawler.DataSourceTest do
  use ExUnit.Case, async: true

  alias MusicListings.Crawler.DataSource
  alias MusicListings.Crawler.Payload
  alias MusicListings.HttpClient.Response

  @moduletag :capture_log

  # A parser driven by the test process: each URL's response and each body's
  # events and next page are looked up from the process dictionary, so every
  # test can describe its own site. DataSource calls the parser synchronously,
  # so the lookups run in the test process.
  defmodule ScriptedParser do
    def retrieve_events_fun do
      fn url ->
        case Process.get({:response, url}) do
          {:raise, error} -> raise error
          response -> response
        end
      end
    end

    def events(body) do
      case Process.get({:events, body}) do
        {:raise, error} -> raise error
        events -> events
      end
    end

    def next_page_url(body, _current_url), do: Process.get({:next_page_url, body})
  end

  @url "https://example.com/events"
  @page_2_url "https://example.com/events?page=2"

  defp respond(url, response), do: Process.put({:response, url}, response)
  defp page(url, body), do: respond(url, {:ok, %Response{status: 200, body: body}})
  defp events(body, events), do: Process.put({:events, body}, events)
  defp next_page(body, url), do: Process.put({:next_page_url, body}, url)

  defp raw_events(payloads), do: Enum.map(payloads, & &1.raw_event)

  describe "retrieve_events/2" do
    test "returns the events from every page" do
      page(@url, "page 1")
      events("page 1", [:event_1])
      next_page("page 1", @page_2_url)
      page(@page_2_url, "page 2")
      events("page 2", [:event_2, :event_3])

      assert {:ok, payloads} = DataSource.retrieve_events(ScriptedParser, @url)
      assert [%Payload{} | _rest] = payloads
      assert [:event_1, :event_2, :event_3] == raw_events(payloads)
    end

    test "treats a page with no events as an empty list" do
      page(@url, "empty")
      events("empty", nil)

      assert {:ok, []} == DataSource.retrieve_events(ScriptedParser, @url)
    end

    test "reports a non-200 status as a fetch error" do
      respond(@url, {:ok, %Response{status: 403, body: "Just a moment..."}})

      assert {:error, {:fetch_error, "HTTP 403 from #{@url}"}, []} ==
               DataSource.retrieve_events(ScriptedParser, @url)
    end

    test "reports a transport failure as a fetch error" do
      respond(@url, {:error, %Req.TransportError{reason: :timeout}})

      assert {:error, {:fetch_error, "Request to #{@url} failed: timeout"}, []} ==
               DataSource.retrieve_events(ScriptedParser, @url)
    end

    test "reports a non-exception error reason as a fetch error" do
      respond(@url, {:error, :curl_impersonate_not_installed})

      assert {:error,
              {:fetch_error, "Request to #{@url} failed: :curl_impersonate_not_installed"}, []} ==
               DataSource.retrieve_events(ScriptedParser, @url)
    end

    test "reports a crash while fetching as a fetch error" do
      respond(@url, {:raise, RuntimeError.exception("no access token")})

      assert {:error, {:fetch_error, "Request to #{@url} crashed: no access token"}, []} ==
               DataSource.retrieve_events(ScriptedParser, @url)
    end

    test "reports a crash in the parser as a page parse error, not a fetch error" do
      page(@url, "page 1")
      events("page 1", {:raise, RuntimeError.exception("selector blew up")})

      assert {:error, {:page_parse_error, message}, []} =
               DataSource.retrieve_events(ScriptedParser, @url)

      assert message =~ "Failed to parse #{@url}"
      assert message =~ "selector blew up"
    end

    test "reports an error returned by the parser as a page parse error" do
      page(@url, "page 1")
      events("page 1", {:error, :bad_markup})

      assert {:error, {:page_parse_error, "Failed to parse #{@url}: :bad_markup"}, []} ==
               DataSource.retrieve_events(ScriptedParser, @url)
    end

    test "keeps the events from earlier pages when a later page fails" do
      page(@url, "page 1")
      events("page 1", [:event_1])
      next_page("page 1", @page_2_url)
      respond(@page_2_url, {:error, %Req.TransportError{reason: :timeout}})

      assert {:error, {:fetch_error, "Request to #{@page_2_url} failed: timeout"}, payloads} =
               DataSource.retrieve_events(ScriptedParser, @url)

      assert [:event_1] == raw_events(payloads)
    end
  end
end
