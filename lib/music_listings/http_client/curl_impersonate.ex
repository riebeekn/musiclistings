defmodule MusicListings.HttpClient.CurlImpersonate do
  @moduledoc """
  Fetches a URL through the `curl-impersonate` binary so the request carries a
  real Chrome TLS/HTTP2 fingerprint.

  Some venues (the mhrth.com family: Massey Hall, Roy Thomson Hall, TD Music
  Hall) sit behind a Cloudflare Managed Challenge keyed on the client's bot
  score. Erlang's `:ssl` stack has a fingerprint (JA3/JA4: cipher and extension
  order, no GREASE) that Cloudflare classes as automated, so every request from
  Finch/Req gets the "Just a moment..." challenge page - from any IP, with any
  headers. The BEAM can't fake that fingerprint, so for those venues we shell
  out to curl-impersonate instead. See `MusicListings.HttpClient.Req` for how
  to opt a request in (`browser: true`).

  The binary is looked up, in order, at `$CURL_IMPERSONATE_BIN`, on `$PATH`, and
  at `bin/curl-impersonate/curl-impersonate` (where `bin/install-curl-impersonate.sh`
  puts it for local development). The Dockerfile installs it on `$PATH` for prod.
  """

  alias MusicListings.HttpClient.Response

  require Logger

  # Which browser fingerprint to present. Must be one of the targets the
  # installed curl-impersonate release supports (see `curl-impersonate --help`).
  @impersonate_target "chrome146"

  @local_install_path "bin/curl-impersonate/curl-impersonate"

  # A system CA bundle, when present, is passed explicitly so the bundled
  # BoringSSL finds it wherever the binary was built to look.
  @ca_bundle "/etc/ssl/certs/ca-certificates.crt"

  # Same retry policy as `MusicListings.HttpClient.Req`: retry the statuses
  # Cloudflare / origins use for "not right now" with bounded exponential
  # backoff. 403 is included because that is what the challenge page returns.
  @retry_statuses [403, 408, 429, 500, 502, 503, 504]
  @max_retry_delay_ms :timer.seconds(30)
  @default_receive_timeout :timer.seconds(30)
  @default_max_retries 3

  # curl needs none of the app's secrets, so don't leak them into its environment.
  @cleared_env Enum.map(
                 ~w(DATABASE_URL PROD_DB_URL SECRET_KEY_BASE BREVO_API_KEY TURNSTILE_SECRET_KEY
                    TICKET_NETWORK_AUTH_TOKEN HONEYBADGER_API_KEY APPSIGNAL_PUSH_API_KEY),
                 &{&1, nil}
               )

  @doc """
  GETs `url` via curl-impersonate. Honours the same `opts` as the Req client:
  `:receive_timeout` and `:max_retries`.
  """
  @spec get(String.t(), list(), keyword()) :: {:ok, Response.t()} | {:error, any()}
  def get(url, headers \\ [], opts \\ []) do
    case binary_path() do
      nil ->
        {:error, :curl_impersonate_not_installed}

      bin ->
        max_retries = Keyword.get(opts, :max_retries, @default_max_retries)
        timeout = Keyword.get(opts, :receive_timeout, @default_receive_timeout)
        request_with_retries(bin, url, headers, timeout, max_retries, 0)
    end
  end

  defp request_with_retries(bin, url, headers, timeout, max_retries, attempt) do
    result = request(bin, url, headers, timeout)

    if retry?(result) and attempt < max_retries do
      delay = min(Integer.pow(2, attempt) * 1_000, @max_retry_delay_ms)
      attempts_left = max_retries - attempt

      Logger.warning(
        "retry: curl-impersonate got #{describe(result)} for #{url}, " <>
          "will retry in #{delay}ms, #{attempts_left} attempt#{if attempts_left == 1, do: "", else: "s"} left"
      )

      Process.sleep(delay)
      request_with_retries(bin, url, headers, timeout, max_retries, attempt + 1)
    else
      result
    end
  end

  defp retry?({:ok, %Response{status: status}}), do: status in @retry_statuses
  defp retry?({:error, _reason}), do: true

  defp describe({:ok, %Response{status: status}}), do: "response with status #{status}"
  defp describe({:error, reason}), do: "error #{inspect(reason)}"

  # curl writes the body to a temp file and only the HTTP status to stdout, so
  # a binary body never has to be split out of curl's own output. On a non-zero
  # exit stdout carries curl's error message instead (stderr is merged in).
  #
  # `bin` is resolved from config / `$CURL_IMPERSONATE_BIN` / `$PATH`, never
  # from request input, and `body_path` is a path we generate ourselves.
  # sobelow_skip ["CI.System", "Traversal.FileModule"]
  defp request(bin, url, headers, timeout) do
    body_path = body_tmp_path()

    max_time = timeout |> div(1_000) |> Integer.to_string()

    args =
      Enum.concat([
        ["--impersonate", @impersonate_target, "--compressed", "--silent", "--show-error"],
        [
          "--location",
          "--max-time",
          max_time,
          "--output",
          body_path,
          "--write-out",
          "%{http_code}"
        ],
        ca_bundle_args(),
        header_args(headers),
        [url]
      ])

    try do
      case System.cmd(bin, args, stderr_to_stdout: true, env: @cleared_env) do
        {status_string, 0} ->
          status = status_string |> String.trim() |> String.to_integer()
          {:ok, Response.new(status, read_body(body_path))}

        {output, exit_code} ->
          {:error, {:curl_impersonate_failed, exit_code, String.trim(output)}}
      end
    rescue
      # e.g. $CURL_IMPERSONATE_BIN points at a file that isn't there
      error in ErlangError ->
        {:error, {:curl_impersonate_failed, error}}
    after
      File.rm(body_path)
    end
  end

  # `body_path` is always a path we generated in `body_tmp_path/0`.
  # sobelow_skip ["Traversal.FileModule"]
  defp read_body(body_path) do
    case File.read(body_path) do
      {:ok, body} -> body
      # curl leaves no file behind for an empty response
      {:error, :enoent} -> ""
    end
  end

  defp body_tmp_path do
    Path.join(
      System.tmp_dir!(),
      "curl-impersonate-#{System.unique_integer([:positive])}.body"
    )
  end

  defp header_args(headers) do
    Enum.flat_map(headers, fn {name, value} -> ["--header", "#{name}: #{value}"] end)
  end

  defp ca_bundle_args do
    if File.exists?(@ca_bundle), do: ["--cacert", @ca_bundle], else: []
  end

  defp binary_path do
    case System.get_env("CURL_IMPERSONATE_BIN", "") do
      "" -> System.find_executable("curl-impersonate") || local_install()
      bin -> bin
    end
  end

  defp local_install do
    path = Path.expand(@local_install_path)
    if File.exists?(path), do: path, else: nil
  end
end
