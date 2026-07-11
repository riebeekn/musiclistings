defmodule MusicListings.HttpClient.ReqTest do
  use ExUnit.Case, async: true

  alias MusicListings.HttpClient.Req, as: ReqClient

  # Requests are routed to this stub rather than the network via the
  # `:req_options` config in config/test.exs.
  @stub MusicListings.HttpClient.Req

  # Values are collected per header name so a header sent twice (a default that
  # failed to be overridden) shows up as a two-element list rather than silently
  # passing an equality assertion.
  defp stub_echoing_headers do
    Req.Test.stub(@stub, fn conn ->
      headers =
        Enum.reduce(conn.req_headers, %{}, fn {name, value}, acc ->
          Map.update(acc, name, [value], &[value | &1])
        end)

      Req.Test.json(conn, headers)
    end)
  end

  describe "get/2 default headers" do
    test "sends browser-like headers when the caller supplies none" do
      stub_echoing_headers()

      {:ok, response} = ReqClient.get("https://example.com")

      assert [user_agent] = response.body["user-agent"]
      assert user_agent =~ "Mozilla/5.0"
      refute user_agent =~ "req/"

      assert response.body["accept"] == [
               "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
             ]

      assert response.body["accept-language"] == ["en-CA,en;q=0.9"]
    end

    test "keeps caller-supplied headers alongside the defaults" do
      stub_echoing_headers()

      {:ok, response} = ReqClient.get("https://example.com", [{"x-api-key", "secret"}])

      assert response.body["x-api-key"] == ["secret"]
      assert [user_agent] = response.body["user-agent"]
      assert user_agent =~ "Mozilla/5.0"
    end

    test "a caller-supplied header overrides the default rather than duplicating it" do
      stub_echoing_headers()

      {:ok, response} = ReqClient.get("https://example.com", [{"User-Agent", "custom-agent"}])

      assert response.body["user-agent"] == ["custom-agent"]
    end
  end

  describe "post/3 default headers" do
    test "sends the default user-agent but lets Req own content-type for the json body" do
      stub_echoing_headers()

      {:ok, response} = ReqClient.post("https://example.com", %{query: "{}"}, [])

      assert [user_agent] = response.body["user-agent"]
      assert user_agent =~ "Mozilla/5.0"
      assert response.body["content-type"] == ["application/json"]
    end
  end

  describe "retries" do
    test "retries a 202 on GET" do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      Req.Test.stub(@stub, fn conn ->
        attempt = Agent.get_and_update(counter, &{&1 + 1, &1 + 1})

        if attempt == 1 do
          conn |> Plug.Conn.put_status(202) |> Req.Test.text("bot mitigation placeholder")
        else
          Req.Test.text(conn, "the real page")
        end
      end)

      {:ok, response} = ReqClient.get("https://example.com")

      assert response.status == 200
      assert response.body == "the real page"
      assert Agent.get(counter, & &1) == 2
    end

    test "does not retry a 202 on POST, where it is a legitimate success" do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      Req.Test.stub(@stub, fn conn ->
        Agent.update(counter, &(&1 + 1))
        conn |> Plug.Conn.put_status(202) |> Req.Test.text("accepted")
      end)

      {:ok, response} = ReqClient.post("https://example.com", %{query: "{}"}, [])

      assert response.status == 202
      assert Agent.get(counter, & &1) == 1
    end
  end
end
