defmodule MusicListings.HttpClient.CurlImpersonateTest do
  # async: false - the binary is located via the CURL_IMPERSONATE_BIN env var
  use ExUnit.Case, async: false

  alias MusicListings.HttpClient.CurlImpersonate
  alias MusicListings.HttpClient.Response

  # A stand-in for the real binary that speaks just enough of curl's CLI for the
  # client: it writes a body to `--output`, prints the status for `--write-out`,
  # and takes the status to return from the last path segment of the URL. It
  # also records the argv it was called with so the test can inspect it.
  @fake_bin """
  #!/bin/bash
  printf '%s\\n' "$@" > "$ARGV_LOG"
  out=""
  url=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --output) out="$2"; shift 2 ;;
      --impersonate|--max-time|--write-out|--header|--cacert) shift 2 ;;
      --*) shift ;;
      *) url="$1"; shift ;;
    esac
  done
  status="${url##*/}"
  if [[ "$status" == "fail" ]]; then
    echo "curl: (6) Could not resolve host" >&2
    exit 6
  fi
  printf 'body for %s' "$url" > "$out"
  printf '%s' "$status"
  """

  setup do
    dir =
      Path.join(System.tmp_dir!(), "curl-impersonate-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    bin = Path.join(dir, "fake-curl-impersonate")
    File.write!(bin, @fake_bin)
    File.chmod!(bin, 0o755)
    argv_log = Path.join(dir, "argv.log")

    previous = System.get_env("CURL_IMPERSONATE_BIN")
    System.put_env("CURL_IMPERSONATE_BIN", bin)
    System.put_env("ARGV_LOG", argv_log)

    on_exit(fn ->
      if previous,
        do: System.put_env("CURL_IMPERSONATE_BIN", previous),
        else: System.delete_env("CURL_IMPERSONATE_BIN")

      System.delete_env("ARGV_LOG")
      File.rm_rf!(dir)
    end)

    %{argv_log: argv_log}
  end

  describe "get/3" do
    test "returns the status and body", %{argv_log: argv_log} do
      assert {:ok, %Response{status: 200, body: "body for https://venue.test/200"}} =
               CurlImpersonate.get("https://venue.test/200", [{"accept", "text/html"}])

      argv = argv_log |> File.read!() |> String.split("\n", trim: true)
      assert ["--impersonate", "chrome146" | _rest] = argv
      assert "--header" in argv
      assert "accept: text/html" in argv
      assert List.last(argv) == "https://venue.test/200"
    end

    test "returns a non-retryable status without retrying" do
      assert {:ok, %Response{status: 404}} =
               CurlImpersonate.get("https://venue.test/404", [], max_retries: 3)
    end

    test "retries a challenge status and returns the last response" do
      assert {:ok, %Response{status: 403}} =
               CurlImpersonate.get("https://venue.test/403", [], max_retries: 1)
    end

    test "returns an error when curl exits non-zero" do
      assert {:error, {:curl_impersonate_failed, 6, "curl: (6) Could not resolve host"}} =
               CurlImpersonate.get("https://venue.test/fail", [], max_retries: 0)
    end

    test "returns an error when the binary is missing" do
      System.put_env("CURL_IMPERSONATE_BIN", "/nonexistent/curl-impersonate")

      assert {:error, {:curl_impersonate_failed, %ErlangError{original: :enoent}}} =
               CurlImpersonate.get("https://venue.test/200", [], max_retries: 0)
    end
  end
end
