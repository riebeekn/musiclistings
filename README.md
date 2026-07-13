# MusicListings

Source code for [https://torontomusiclistings.com](https://torontomusiclistings.com), a music listings aggregator for the Toronto area
written in [Elixir](https://elixir-lang.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/welcome.html).

## Table of Contents

- [Running the app locally](#running-the-app-locally)
  - [Tests and code quality](#tests-and-code-quality)
  - [Helper scripts](#helper-scripts)
- [Admin functionality](#admin-functionality)
- [Feature flags](#feature-flags)
- [HTTP Client config](#http-client-config)
- [UI](#ui)
- [Crawling and Event population](#crawling-and-event-population)
  - [Background jobs](#background-jobs)
  - [Parsing modules](#parsing-modules)
  - [Adding a new venue](#adding-a-new-venue)
  - [Venues Render can't reach](#venues-render-cant-reach)
- [Monitoring](#monitoring)
- [Hosting and Infrastructure](#hosting-and-infrastructure)
  - [GitHub Actions](#github-actions)
  - [Terraform](#terraform)
  - [Render Remote access](#render-remote-access)
    - [Database](#render-database-access)
    - [IEX](#render-iex-access)
  - [Releases](#releases)
    - [Generate the release files](#generate-the-release-files)
    - [Build the release](#build-the-release)
    - [Run the release](#run-the-release)
  - [Docker](#docker)
    - [Generate the docker file](#generate-the-docker-file)
    - [Build the docker image](#build-the-docker-image)
    - [Run the docker image](#run-the-docker-image)

## Running the app locally

Erlang / Elixir versions are pinned in `.tool-versions` ([asdf](https://asdf-vm.com/) / [mise](https://mise.jdx.dev/)).  A local PostgreSQL server is also required.

- Copy `.envrc_template` to `.envrc` and update / source the required environment variables (or install [direnv](https://direnv.net/docs/installation.html)):
  - `ADMIN_EMAIL` - the email address the application will send communications to.  The application sends an email summary of the nightly event population runs and also when an event is submitted via the UI.  In development these emails are not actually sent, they are available at [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox) instead.  See [http://localhost:4000/dev/gallery](http://localhost:4000/dev/gallery) for a preview of the emails.
  - `PROD_DB_URL` - Render's **external** Postgres connection string.  Only needed for the [helper scripts](#helper-scripts) that talk to the production database (`bin/pull-prod-db.sh`, `bin/crawl-venue.sh`); the app itself doesn't need it.  Requires your IP to be on the Render database's inbound allowlist.
- Install dependencies and set up the database: `mix setup` (this runs `deps.get`, `ecto.setup` and builds assets).
- Run the server (`iex -S mix phx.server`).  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
- A fresh local database has venues but no events.  To populate events, either:
  - Run the crawler from `iex`: `MusicListings.Workers.DataRetrievalWorker.perform(%{})` (this crawls every venue and takes a while), or
  - Crawl a single venue: `mix crawl_venue DanforthMusicHallParser`, or
  - Pull down the latest production data with `./bin/pull-prod-db.sh` (fastest, requires `PROD_DB_URL`).

### Tests and code quality

```
mix test                # run the test suite
mix coveralls.html      # test suite with a coverage report
mix check               # format, credo --strict, compile --warnings-as-errors, xref cycle checks, dialyzer, docs
```

Both `mix check` and `mix test` should be run and passing before opening a PR - CI runs the same checks.

### Helper scripts

The scripts in `bin/` each document their own usage in a header comment:

- `bin/pull-prod-db.sh` - dumps the production database and restores it into the local dev database, so you can work against real crawl data.
- `bin/crawl-venue.sh` - crawls the given venues from your machine and writes the results **straight to production**.  See [Venues Render can't reach](#venues-render-cant-reach).
- `bin/start-ngrok-server.sh` / `bin/stop-ngrok-server.sh` - exposes the local dev server over an ngrok tunnel and prints a QR code, for checking mobile-only behaviour without deploying.

## Admin functionality

Admin functionality is only available when logged in to the application.  Once logged in you can:

- Delete events from the `/events` and `/events/venue/:venue_id` pages.
- Review, edit and approve user submitted events at `/submitted_events`.
- Toggle [feature flags](#feature-flags) at `/feature_flags`.
- Add a venue at `/venues/new`.

User management is handled by [Phx Gen Auth](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html).  Much of the UI component of `Phx Gen Auth` has been removed as there is no need for users to create accounts etc.  As a result the admin user needs to be created via `iex`, i.e. open an `iex` session and run the following:

```
MusicListings.Accounts.register_user(%{email: "bob_admin@example.com", password: "some_password"})
```

Now you can login at `/users/log_in`.

## Feature flags

Feature flags are handled by [FunWithFlags](https://github.com/tompave/fun_with_flags), persisted via Ecto in the `feature_flags` table (no Redis).  The in-memory cache is deliberately **disabled** (see `config/config.exs`) so that toggles take effect immediately with no staleness and no need for cross-node cache busting.  The tradeoff is that every check hits the database, so check a flag once per request and reuse the boolean rather than calling `FunWithFlags.enabled?/1` in a loop.

Flags can be toggled from the admin UI at `/feature_flags`.

## HTTP Client config

The http client is configurable via the following setting in `config/config.exs`:

```
config :music_listings, :http_client, MusicListings.HttpClient.Req
```

[Req](https://github.com/wojtekmach/req) is what the app uses everywhere outside of tests (see `lib/music_listings/http_client/req.ex`), where it handles `brotli`/`gzip` decoding, timeouts and retries.  It runs against a dedicated Finch pool (`MusicListings.ReqFinch`, started in `lib/music_listings/application.ex`) so that crawling doesn't contend with the pool used for sending email.

The test environment swaps in `MusicListings.HttpClient.Test`, which serves the HTML fixtures under `test/data/` instead of making real requests.

To add a new http client add a module at `lib/music_listings/http_client/` and implement the `lib/music_listings/http_client.ex` behaviour.

There used to be an `HTTPoison` implementation as well, added as a workaround when `Req`'s `brotli` decoding was failing on some sites.  `Req` handles those sites fine now, so both the module and the dependency have been removed.

## UI

The UI is a standard Phoenix LiveView application.

Venue filtering persistence is accomplished via local storage, see the `VenueFilter` hook in `assets/js/app.js` which gets called from `lib/music_listings_web/live/event_live/index.ex`.

## Crawling and Event population

Events are populated nightly by a [Render Cron](https://render.com/docs/cronjobs) job.  The cron job boots the app with `CRAWL_AND_EXIT=true`; the `crawl_and_exit?` branch of `lib/music_listings/application.ex` then starts only the supervision tree the crawler needs (no web endpoint, no Oban), runs `MusicListings.Workers.DataRetrievalWorker`, and shuts the node down.  The worker hands off to `lib/music_listings/crawler.ex`, which performs retrieval, parsing and storage of events.

This used to be an [Oban](https://github.com/oban-bg/oban) cron job running inside the web service.  Crawling takes a fair bit of memory, which meant paying for a larger instance year round just to service one nightly job.  Running it as a separate Render Cron job lets the main application run on a cheaper instance.  The `DataRetrievalWorker` is still an Oban worker (and its old crontab entry is still in `config/config.exs`, commented out), it's just no longer scheduled by Oban.

The crawler implementation is not very memory efficient.  A list of `payload` structs are built up in memory for each event being parsed.  This might be worth refactoring in the future.

Once event population has concluded an email is sent to the configured `ADMIN_EMAIL` with details of the crawl.  Results are also captured in the `crawl_summaries`, `venue_crawl_summaries` and `crawl_errors` database tables.

### Background jobs

Oban still runs inside the web service and handles the scheduled jobs that aren't the crawl (see the crontab in `config/config.exs`):

- `ParserHealthWorker` - daily; scans recent crawl history for venues whose parser yield has dropped off and emails the findings to `ADMIN_EMAIL`.  This is how a silently broken parser gets noticed.
- `NewThisWeekAnalyticsWorker` - Mondays; emails the weekly "New This Week" rail traction report.
- `PurgeEventsWorker` - purges historical events.  Currently switched off (its crontab entry is commented out).

### Parsing modules

The code that performs event parsing for individual venues is located in `lib/music_listings/parsing/venue_parsers`.  Each venue has a parser and parsers implement the `lib/music_listings/parsing/venue_parser.ex` behaviour.  Each parser returns a list of `Payload` structs.

Many venues run on a common platform (LiveNation, SquareSpace, WordPress, Dice, Wix, Resident Advisor, etc.), so `lib/music_listings/parsing/venue_parsers/base_parsers` holds reusable base parsers for those platforms.  A venue parser on one of those platforms is usually a thin module that configures the relevant base parser.  Shared helpers live in `lib/music_listings/parsing/parse_helpers.ex`.

Any errors encountered during parsing will be inserted into the `crawl_errors` database table and included in the aforementioned crawl results email.

### Adding a new venue

1. Create a parser at `lib/music_listings/parsing/venue_parsers/[venue_name]_parser.ex` implementing the `VenueParser` behaviour (inherit from a base parser if the venue is on a known platform).
2. Add the venue to the `venues` table via a migration in `priv/repo/migrations/`.  Populate `google_map_url` with a Google Maps URL that includes a pin marker for the venue.
3. Add example data files at `test/data/[venue_name]/` and a test at `test/music_listings/parsing/venue_parsers/[venue_name]_parser_test.exs`.
4. Verify the venue crawls end to end with `mix crawl_venue [VenueName]Parser`.

A couple of things worth knowing:

- If a venue's events are recurring and share a duplicate id, build the event id from a combination of the venue name and the event date so that each occurrence is inserted.  `ParseHelpers.build_id_from_venue_and_date/2` and `build_id_from_venue_and_datetime/2` exist for this.
- Be mindful of rate limits when browsing a venue's site - don't hammer it with requests.

### Venues Render can't reach

Some venues' origin servers silently drop Render's egress IP at the TCP layer, so the nightly crawl can never reach them - the connection times out before a single HTTP byte is sent (`%Req.TransportError{reason: :timeout}`).  This is **not** fixable in a parser: no header, user agent or retry helps, because the origin never completes the TCP handshake.

These sites *are* reachable from a home/residential connection, so they get crawled locally instead:

```
./bin/crawl-venue.sh WiggleRoomParser
./bin/crawl-venue.sh WiggleRoomParser JunctionUndergroundParser
```

That runs `mix crawl_venue` with `USE_PROD_DB=true`, which points the dev app at the production database via `$PROD_DB_URL` (see `config/dev.exs`) so the results land in prod.  Venues are identified by their `parser_module_name` rather than their id, since ids are assigned per environment.  The nightly crawl summary email prints the exact command to run for any venue that reported "No events found".

Currently affected: **Wiggle Room** and **Junction Underground** (both on the same Hostinger box).

## Monitoring

- [Honeybadger](https://www.honeybadger.io/) for error reporting (`HONEYBADGER_API_KEY`).
- [AppSignal](https://www.appsignal.com/) for APM, log forwarding and cron check-ins (`APPSIGNAL_PUSH_API_KEY`).  AppSignal is only activated when the push key is set, so it stays inactive in dev/test.  The nightly crawl is wrapped in an AppSignal cron check-in (`daily_crawl`) so a missed or failed run alerts.
- Phoenix LiveDashboard is mounted in development only, at [http://localhost:4000/dev/dashboard](http://localhost:4000/dev/dashboard).

## Hosting and Infrastructure

The application is hosted on [Render](https://render.com/).  It was initially deployed to [fly.io](https://fly.io/), but having a Terraform provider available for Render made me decide to switch.  The application uses CloudFlare as a reverse proxy.

Deployment and infrastructure setup is handled by a combination of Terraform and GitHub Actions.

### GitHub Actions

GitHub actions control deployments and are located in `.github/workflows/ci.yml`.  On a successful build the application is deployed to Render (which environments are deployed is driven by the `RENDER_ENVIRONMENTS` and `RENDER_CRON_ENVIRONMENTS` GitHub Action variables; `prod` only deploys from `main`).

### Terraform

There are 2 Terraform projects which serve the following purposes:

- `.infrastructure/production` - Represents initial production infrastructure that was set up manually and has since been imported into Terraform, currently just contains some CloudFlare DNS and Turnstile settings.
- `.infrastructure/render` - Contains Render specific infrastructure files.

See the `README.md` files located in each of the projects for specific information on running the Terraform deployments.  In general the `production` project should never need to be run.

The Render module's per-workspace variables are stored in 1Password as Secure Note items named `<workspace>.tfvars` (e.g. `staging.tfvars`, `prod.tfvars`).  The `tf_plan.sh` / `tf_apply.sh` / `tf_destroy.sh` wrappers pull them at runtime into a temp file that is deleted on exit, so they are never written to git or left on disk.  The 1Password account and vault come from `OP_ACCOUNT` / `OP_VAULT` in the gitignored `.envrc` (see `.infrastructure/render/.example.envrc`).

### Render Remote access

Remote access is available to both the database and console in Render.

#### Render Database access

To access the database for an environment, retrieve the connection information from the terraform output.  This can be done from the `.infrastructure/render` directory.  Make sure you are in the correct workspace and then run:

```
terraform output -json db_connection_info
```

This will output an `external_connection_string` which can be used with a SQL client to connect to the database.

#### Render IEX access

I haven't gotten SSH to work from the console for some reason.  So instead use the console available from the render service dashboard, for example: [https://dashboard.render.com/web/srv-cu5shed6l47c73bshhrg/shell](https://dashboard.render.com/web/srv-cu5shed6l47c73bshhrg/shell).

IEX can then be started via:

```
/bin/sh -c 'bin/music_listings remote'
```

### Releases

The Phoenix application itself is deployed using releases and docker.  If for some reason you need to debug the release, the release can be generated / run locally via:

#### Generate the release files

```
mix release.init
```

#### Build the release

```
mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite=true
```

#### Run the release

```
SECRET_KEY_BASE=$(mix phx.gen.secret) \
PHX_SERVER=true \
DATABASE_URL=postgres://postgres:postgres@localhost:5432/music_listings_dev \
BREVO_API_KEY="nope" \
TURNSTILE_SITE_KEY="nope" \
TURNSTILE_SECRET_KEY="nope" \
_build/prod/rel/music_listings/bin/music_listings start
```

**Note:** unless you need to actually test sending emails or turnstile, fake values can be set for these.

You can now access the application at localhost.

### Docker

If you need to debug the docker container locally, it can be generated / run locally with Docker Desktop via:

#### Generate the docker file

**Note:** you might need to adjust tool versions versions to generate the docker file.

```
mix phx.gen.release --docker
```

#### Build the docker image

```
docker build --tag musiclistings_latest .
```

#### Run the docker image

```
docker run -it -p 4000:4000 \
  --env SECRET_KEY_BASE=$(mix phx.gen.secret) \
  --env DATABASE_URL=postgres://nick:postgres@host.docker.internal:5432/music_listings_dev \
  --env PHX_SERVER=$PHX_SERVER \
  --env DB_SSL=false \
  --env LOG_LEVEL=debug \
  --env ADMIN_EMAIL=$ADMIN_EMAIL \
  --env BREVO_API_KEY="nope" \
  --env TURNSTILE_SITE_KEY="nope" \
  --env TURNSTILE_SECRET_KEY="nope" \
  musiclistings_latest
```

You can now access the application at localhost.
