defmodule MusicListings.HttpClient.SiteGroundChallenge do
  @moduledoc """
  Solves SiteGround's `sgcaptcha` proof-of-work bot challenge so we can crawl
  venues hosted there.

  SiteGround's AI-bot protection intercepts requests from datacenter IPs (our
  crawler runs on Render) and answers a page GET with a `202` whose body is a
  meta-refresh to `/.well-known/sgcaptcha/`. That endpoint serves a hashcash
  challenge string `"<complexity>:<ts>:<id>:<hash>:"` and asks the browser to
  find a nonce N such that `SHA1(challenge_string <> N)` has `complexity`
  leading zero bits, then GET the submit URL with the winning preimage
  (hex-encoded) as `?sol=...` to receive a clearance cookie. Re-fetching the
  page with that cookie returns the real content. This module reproduces that
  handshake headlessly — no JS engine needed, just `:crypto` and a cookie jar.

  Use it from a parser's `retrieve_events_fun/0` in place of
  `MusicListings.HttpClient.get/1`.

  It degrades gracefully: at 200 (not challenged) it returns the page directly,
  and if any step of the challenge is unrecognised it returns the raw challenged
  response, so the caller logs it exactly as it would have before.
  """
  import Bitwise

  alias MusicListings.HttpClient.Req, as: ReqClient
  alias MusicListings.HttpClient.Response

  require Logger

  # Runtime guard: refuse to solve absurd difficulties. Current live value is 21
  # (~2^21 hashes, well under a second). 24 leaves headroom for SiteGround
  # nudging it up while capping the worst case at a few seconds; anything higher
  # we decline and log, degrading to "no events" rather than hanging the crawl.
  @max_complexity 24

  # Give-up bound at 20x the expected 2^complexity attempts — high enough that a
  # false give-up is astronomically unlikely, low enough to stay finite.
  @solve_multiplier 20

  @spec get(String.t()) :: {:ok, Response.t()} | {:error, any()}
  def get(url) do
    case request(url, %{}) do
      {:ok, resp} ->
        case challenge_path(resp.body) do
          nil -> {:ok, Response.new(resp.status, resp.body)}
          path -> solve_challenge(url, path, resp)
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp solve_challenge(page_url, challenge_path, original) do
    result =
      with {:ok, challenge_page} <- request(absolute(page_url, challenge_path), original.cookies),
           {:ok, params} <- parse_challenge(challenge_page.body),
           :ok <- check_complexity(params.complexity),
           {:ok, solution, hashes, elapsed_ms} <- solve(params.challenge, params.complexity),
           submit_url <- absolute(page_url, build_submit(params, solution, elapsed_ms, hashes)),
           {:ok, submit_page} <- request(submit_url, challenge_page.cookies),
           {:ok, final} <- request(page_url, submit_page.cookies) do
        Logger.info(
          "Solved SiteGround challenge for #{page_url} in #{hashes} hashes (#{elapsed_ms}ms), status #{final.status}"
        )

        {:ok, Response.new(final.status, final.body)}
      end

    case result do
      {:ok, _response} = ok ->
        ok

      _unrecognised ->
        Logger.warning(
          "Could not complete SiteGround challenge for #{page_url}; returning challenge response"
        )

        {:ok, Response.new(original.status, original.body)}
    end
  end

  # Extracts the sgcaptcha path from the 202 body's meta-refresh, e.g.
  # `content="0;/.well-known/sgcaptcha/?r=%2Fevent-calendar%2F&y=ipc:..."`.
  defp challenge_path(body) when is_binary(body) do
    case Regex.run(~r/content="0;([^"]*sgcaptcha[^"]*)"/, body, capture: :all_but_first) do
      [path] -> path
      _no_match -> nil
    end
  end

  defp challenge_path(_body), do: nil

  defp parse_challenge(body) when is_binary(body) do
    with [challenge] <- Regex.run(~r/sgchallenge="([^"]+)"/, body, capture: :all_but_first),
         [submit_url] <- Regex.run(~r/sgsubmit_url="([^"]+)"/, body, capture: :all_but_first),
         [complexity_str | _rest] <- String.split(challenge, ":"),
         {complexity, ""} <- Integer.parse(complexity_str) do
      {:ok, %{challenge: challenge, submit_url: submit_url, complexity: complexity}}
    else
      _unrecognised -> :error
    end
  end

  defp parse_challenge(_body), do: :error

  defp check_complexity(complexity) when complexity in 1..@max_complexity, do: :ok

  defp check_complexity(complexity) do
    Logger.warning(
      "SiteGround challenge complexity #{complexity} exceeds cap #{@max_complexity}; not solving"
    )

    :error
  end

  # Find a nonce so SHA1(challenge <> nonce) has `complexity` leading zero bits;
  # the solution submitted to the server is the hex of that winning preimage.
  # Times the search so we can send the `s=<ms>:<hashes>` the endpoint expects.
  defp solve(challenge, complexity) do
    max_hashes = trunc(:math.pow(2, complexity)) * @solve_multiplier
    started_at = System.monotonic_time(:millisecond)

    case search(challenge, complexity, 0, max_hashes) do
      {:ok, preimage, hashes} ->
        elapsed_ms = System.monotonic_time(:millisecond) - started_at
        {:ok, Base.encode16(preimage, case: :lower), hashes, elapsed_ms}

      :error ->
        :error
    end
  end

  defp search(_challenge, _complexity, nonce, max_hashes) when nonce > max_hashes, do: :error

  defp search(challenge, complexity, nonce, max_hashes) do
    preimage = challenge <> nonce_bytes(nonce)
    <<word::32, _rest::binary>> = :crypto.hash(:sha, preimage)

    if bsr(word, 32 - complexity) == 0 do
      {:ok, preimage, nonce}
    else
      search(challenge, complexity, nonce + 1, max_hashes)
    end
  end

  # Minimal big-endian encoding of the nonce, matching the challenge JS (1-4 bytes).
  defp nonce_bytes(nonce) when nonce <= 0xFF, do: <<nonce::8>>
  defp nonce_bytes(nonce) when nonce <= 0xFFFF, do: <<nonce::16>>
  defp nonce_bytes(nonce) when nonce <= 0xFFFFFF, do: <<nonce::24>>
  defp nonce_bytes(nonce), do: <<nonce::32>>

  defp build_submit(%{submit_url: submit_url}, solution, elapsed_ms, hashes) do
    separator = if String.contains?(submit_url, "?"), do: "&", else: "?"

    submit_url <>
      separator <> "sol=" <> URI.encode_www_form(solution) <> "&s=#{elapsed_ms}:#{hashes}"
  end

  defp absolute(base_url, path), do: base_url |> URI.merge(path) |> URI.to_string()

  # A single request in the handshake. Returns status, body and the cookie jar
  # (the passed-in jar merged with this response's Set-Cookie). Redirects and
  # retries are off: we drive the multi-step flow ourselves and the 202 is the
  # challenge, not something to retry.
  defp request(url, cookies) do
    case Req.get(url, request_options(cookies)) do
      {:ok, response} ->
        {:ok,
         %{
           status: response.status,
           body: response.body,
           cookies: merge_cookies(cookies, set_cookies(response))
         }}

      {:error, _reason} = error ->
        error
    end
  end

  defp request_options(cookies) do
    [
      headers: request_headers(cookies),
      compressed: true,
      finch: MusicListings.ReqFinch,
      receive_timeout: 30_000,
      redirect: false,
      retry: false
    ] ++ Application.get_env(:music_listings, :req_options, [])
  end

  defp request_headers(cookies) when map_size(cookies) == 0, do: ReqClient.default_headers()

  defp request_headers(cookies) do
    [{"cookie", cookie_header(cookies)} | ReqClient.default_headers()]
  end

  defp set_cookies(response) do
    response
    |> Req.Response.get_header("set-cookie")
    |> Enum.map(&parse_set_cookie/1)
  end

  # Parse a Set-Cookie into `{name, value, deleted?}`. A non-positive Max-Age is
  # a deletion (the challenge page clears a `nevercache-*` cookie this way).
  defp parse_set_cookie(header) do
    [pair | attributes] = String.split(header, ";")
    {name, value} = split_pair(pair)

    deleted? =
      Enum.any?(attributes, fn attribute ->
        case attribute |> String.trim() |> String.downcase() |> split_pair() do
          {"max-age", max_age} ->
            match?({age, _rest} when age <= 0, Integer.parse(max_age))

          _other ->
            false
        end
      end)

    {name, value, deleted?}
  end

  defp split_pair(pair) do
    case String.split(pair, "=", parts: 2) do
      [name, value] -> {String.trim(name), String.trim(value)}
      [name] -> {String.trim(name), ""}
    end
  end

  defp merge_cookies(jar, cookies) do
    Enum.reduce(cookies, jar, fn
      {name, _value, true}, acc -> Map.delete(acc, name)
      {name, value, false}, acc -> Map.put(acc, name, value)
    end)
  end

  defp cookie_header(jar) do
    jar |> Enum.map_join("; ", fn {name, value} -> "#{name}=#{value}" end)
  end
end
