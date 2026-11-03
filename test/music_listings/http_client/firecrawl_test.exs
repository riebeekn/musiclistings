defmodule MusicListings.HttpClient.FirecrawlTest do
  # async: false - the API key is read from the application env
  use ExUnit.Case, async: false

  alias MusicListings.HttpClient.Firecrawl
  alias MusicListings.HttpClient.Response

  @url "https://masseyhall.mhrth.com/tickets/?page=1"

  setup do
    previous = Application.get_env(:music_listings, :firecrawl_api_key)

    on_exit(fn ->
      Application.put_env(:music_listings, :firecrawl_api_key, previous)
    end)

    test_pid = self()

    # Reports each request the stub receives back to the test
    stub = fn response_fun ->
      Req.Test.stub(Firecrawl, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        send(
          test_pid,
          {:request, Plug.Conn.get_req_header(conn, "authorization"), Jason.decode!(body)}
        )

        response_fun.(conn)
      end)
    end

    %{stub: stub}
  end

  test "returns the target's status and the rendered page", %{stub: stub} do
    stub.(&Req.Test.json(&1, scrape_response(200, "<html>listing</html>")))

    assert {:ok, %Response{status: 200, body: "<html>listing</html>"}} == Firecrawl.get(@url)

    assert_received {:request, _authorization,
                     %{"url" => @url, "formats" => ["rawHtml"], "maxAge" => 0}}
  end

  test "a page the target challenged is still a response, with its status", %{stub: stub} do
    stub.(&Req.Test.json(&1, scrape_response(403, "<html>Just a moment...</html>")))

    assert {:ok, %Response{status: 403}} = Firecrawl.get(@url)
  end

  test "a scrape Firecrawl couldn't carry out is an error", %{stub: stub} do
    stub.(fn conn ->
      conn
      |> Plug.Conn.put_status(400)
      |> Req.Test.json(%{"success" => false, "error" => "DNS resolution failed"})
    end)

    assert {:error, {:firecrawl_failed, 400, "DNS resolution failed"}} == Firecrawl.get(@url)
  end

  test "retries when Firecrawl's own API is unavailable", %{stub: stub} do
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    stub.(fn conn ->
      if Agent.get_and_update(attempts, &{&1, &1 + 1}) == 0 do
        Plug.Conn.send_resp(conn, 502, "Bad Gateway")
      else
        Req.Test.json(conn, scrape_response(200, "<html>listing</html>"))
      end
    end)

    assert {:ok, %Response{status: 200}} = Firecrawl.get(@url)
    assert 2 == Agent.get(attempts, & &1)
  end

  test "retries a rate-limited scrape once the window resets", %{stub: stub} do
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    stub.(fn conn ->
      if Agent.get_and_update(attempts, &{&1, &1 + 1}) == 0 do
        conn
        |> Plug.Conn.put_resp_header("retry-after", "0")
        |> Plug.Conn.put_status(429)
        |> Req.Test.json(%{"success" => false, "error" => "Rate limit exceeded."})
      else
        Req.Test.json(conn, scrape_response(200, "<html>listing</html>"))
      end
    end)

    assert {:ok, %Response{status: 200}} = Firecrawl.get(@url)
    assert 2 == Agent.get(attempts, & &1)
  end

  test "a scrape still rate limited after its retries is an error", %{stub: stub} do
    stub.(fn conn ->
      conn
      |> Plug.Conn.put_status(429)
      |> Req.Test.json(%{"success" => false, "error" => "Rate limit exceeded."})
    end)

    assert {:error, {:firecrawl_failed, 429, "Rate limit exceeded."}} == Firecrawl.get(@url)
  end

  test "authenticates with the API key when there is one", %{stub: stub} do
    stub.(&Req.Test.json(&1, scrape_response(200, "")))

    Application.put_env(:music_listings, :firecrawl_api_key, "fc-test")
    Firecrawl.get(@url)
    assert_received {:request, ["Bearer fc-test"], _body}

    Application.put_env(:music_listings, :firecrawl_api_key, nil)
    Firecrawl.get(@url)
    assert_received {:request, [], _body}
  end

  defp scrape_response(status, html) do
    %{
      "success" => true,
      "data" => %{"rawHtml" => html, "metadata" => %{"statusCode" => status}}
    }
  end
end
