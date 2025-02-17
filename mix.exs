defmodule MusicListings.MixProject do
  use Mix.Project

  def project do
    [
      app: :music_listings,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # Docs
      name: "Music Listings",
      docs: [
        main: "MusicListings",
        source_url: "https://github.com/tbd",
        formatters: ["html"]
      ],
      dialyzer: [
        plt_local_path: "_dialyzer",
        plt_core_path: "_dialyzer",
        plt_add_apps: [:mix]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MusicListings.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0.3", override: true},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:req, "~> 0.5.0"},
      {:brotli, "~> 0.3.0"},
      # {:brotli, git: "https://github.com/yjh0502/erl-brotli", branch: "bugfix/issue-21", override: true},
      {:httpoison, "~> 2.0"},
      {:meeseeks, "~> 0.17.0"},
      {:oban, "~> 2.17"},
      {:premailex, "~> 0.3.0"},
      {:mjml, "~> 1.5.0"},
      {:floki, ">= 0.30.0"},
      {:tzdata, "~> 1.1"},
      {:scrivener_ecto, "~> 3.0"},
      {:redirect, "~> 0.4.0"},
      {:goal, "~> 1.0"},
      {:error_tracker, "~> 0.2"},
      {:phoenix_turnstile, "~> 1.0"},
      # {:ecto_boot_migration, "~> 0.3.0"},
      {:ecto_boot_migration,
       git: "https://github.com/mwhitworth/ecto_boot_migration", branch: "elixir-1.17-fix"},
      {:nimble_csv, "~> 1.2"},
      # build / dev / test related deps
      {:swoosh_gallery, "~> 0.2.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:eunomo, "~> 3.0.0", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.16", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind music_listings", "esbuild music_listings"],
      "assets.deploy": [
        "tailwind music_listings --minify",
        "esbuild music_listings --minify",
        "phx.digest"
      ],
      check: ["format", "credo --strict", "compile --warnings-as-errors", "dialyzer", "docs"]
    ]
  end
end
