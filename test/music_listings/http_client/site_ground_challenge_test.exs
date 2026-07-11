defmodule MusicListings.HttpClient.SiteGroundChallengeTest do
  use ExUnit.Case, async: true

  import Bitwise

  alias MusicListings.HttpClient.SiteGroundChallenge

  # Requests are routed to a Req.Test stub via the :req_options seam in
  # config/test.exs, whose owner name is MusicListings.HttpClient.Req.
  @stub MusicListings.HttpClient.Req

  # Low complexity keeps the proof-of-work instant while still exercising the
  # real SHA-1 search; the stub below only grants the cookie for a valid solve.
  @complexity 8
  @challenge "#{@complexity}:1700000000:abc123:deadbeef:"

  @page_path "/event-calendar/"
  @sgcaptcha_path "/.well-known/sgcaptcha/"
  @refresh_202 ~s(<html><head><meta http-equiv="refresh" content="0;#{@sgcaptcha_path}?r=%2Fevent-calendar%2F&y=ipc:1.2.3.4:1"></meta></head></html>)
  @challenge_html ~s(<html><head><script>const sgchallenge="#{@challenge}";const sgsubmit_url="#{@sgcaptcha_path}?r=%2Fevent-calendar%2F";</script></head></html>)
  @real_page ~s(<div class="entry-content"><script>events: [{ title: 'Real Show' }]</script></div>)

  defp cookie_header(conn) do
    case List.keyfind(conn.req_headers, "cookie", 0) do
      {"cookie", value} -> value
      nil -> ""
    end
  end

  # Mirrors the server's check: hex decodes to `challenge <> nonce` and
  # SHA1(preimage) has @complexity leading zero bits.
  defp valid_solution?(sol) do
    with {:ok, preimage} <- Base.decode16(sol, case: :lower),
         true <- String.starts_with?(preimage, @challenge) do
      <<word::32, _rest::binary>> = :crypto.hash(:sha, preimage)
      bsr(word, 32 - @complexity) == 0
    else
      _invalid -> false
    end
  end

  defp stub_full_handshake do
    Req.Test.stub(@stub, &handshake_response/1)
  end

  defp handshake_response(conn) do
    cookies = cookie_header(conn)
    params = URI.decode_query(conn.query_string)

    cond do
      conn.request_path == @page_path and String.contains?(cookies, "sg_clearance=allow") ->
        Req.Test.html(conn, @real_page)

      conn.request_path == @page_path ->
        conn |> Plug.Conn.put_status(202) |> Req.Test.html(@refresh_202)

      conn.request_path == @sgcaptcha_path and Map.has_key?(params, "sol") ->
        submit_response(conn, params["sol"])

      conn.request_path == @sgcaptcha_path ->
        conn
        |> Plug.Conn.put_resp_cookie("PHPSESSID", "session123")
        |> Req.Test.html(@challenge_html)
    end
  end

  defp submit_response(conn, sol) do
    if valid_solution?(sol) do
      conn
      |> Plug.Conn.put_resp_cookie("sg_clearance", "allow")
      |> Req.Test.html("cleared")
    else
      conn |> Plug.Conn.put_status(403) |> Req.Test.html("bad solution")
    end
  end

  test "solves the challenge and returns the real page" do
    stub_full_handshake()

    {:ok, response} = SiteGroundChallenge.get("https://venue.test#{@page_path}")

    assert response.status == 200
    assert response.body =~ "Real Show"
    refute response.body =~ "sgcaptcha"
  end

  test "returns the page directly when not challenged" do
    Req.Test.stub(@stub, fn conn ->
      assert conn.request_path == @page_path
      Req.Test.html(conn, @real_page)
    end)

    {:ok, response} = SiteGroundChallenge.get("https://venue.test#{@page_path}")

    assert response.status == 200
    assert response.body =~ "Real Show"
  end

  test "degrades to the challenge response when the challenge is unrecognised" do
    Req.Test.stub(@stub, fn conn ->
      cond do
        conn.request_path == @page_path ->
          conn |> Plug.Conn.put_status(202) |> Req.Test.html(@refresh_202)

        conn.request_path == @sgcaptcha_path ->
          # No sgchallenge script - format we can't solve.
          Req.Test.html(conn, "<html><body>unexpected</body></html>")
      end
    end)

    {:ok, response} = SiteGroundChallenge.get("https://venue.test#{@page_path}")

    assert response.status == 202
    assert response.body =~ "sgcaptcha"
  end
end
