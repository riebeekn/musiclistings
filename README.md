# MusicListings

Source code for [https://torontomusiclistings.com](https://torontomusiclistings.com), a music listings aggregator for the Toronto area
written in [Elixir](https://elixir-lang.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/welcome.html).

## Table of Contents

- [Running the app locally](#running-the-app-locally)
- [Admin functionality](#admin-functionality)
- [HTTP Client config](#http-client-config)
- [UI](#ui)
- [Crawling and Event population](#crawling-and-event-population)
  - [Parsing modules](#parsing-modules)
  - [Adding a new venue](#adding-a-new-venue)
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
- Copy `.envrc_template` to `.envrc` and update / source the required environment
variables.
  - Environment variables:
    - `ADMIN_EMAIL` - the email address the application will send communications to.  The application sends an email summary of the nightly event population runs and also when an event is submitted via the UI.  In development these emails will not be sent but instead be available at [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox).  See [http://localhost:4000/dev/gallery](http://localhost:4000/dev/gallery) for a preview of the emails.
- Run the server (`iex -S mix phx.server`).  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
- Events are populated via an Oban Job at 7am UTC.  **NOTE:** on production this has changed to a Render Cron job, see details in the [Crawling and Event population](#crawling-and-event-population) section.
- To manually populate the events, run the worker directly from `iex`: `MusicListings.Workers.DataRetrievalWorker.perform(%{})`.
- To run the tests: `mix test`.

## Admin functionality
Currently there is limited admin functionality (just the ability to delete events).  The Admin functionality is only available when logged in to the application.  

User management is handled by [Phx Gen Auth](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html).  Much of the UI component of `Phx Gen Auth` has been removed as there is no need for users to create accounts etc.  As a result the admin user needs to be created via `iex`, i.e. open an `iex` session and run the following:
```
MusicListings.Accounts.register_user(%{email: "bob_admin@example.com", password: "some_password"})
```

Now you can login at `/users/log_in`.  When logged in, delete links will be available on both the `/events` and `/events/venue/xx` pages.

## HTTP Client config
The http client is configurable via the following setting in `config/config.exs`:
```
config :music_listings, :http_client, MusicListings.HttpClient.HTTPoison
```
Modules currently exist for [Req](https://github.com/wojtekmach/req) and [HTTPoison](https://github.com/edgurgel/httpoison) (see `lib/music_listings/http_client/req.ex` and `lib/music_listings/http_client/httpoison.ex`).

To add a new http client add a module at `lib/music_listings/http_client/` and implement the `lib/music_listings/http_client.ex` behaviour.

Initially the http client was not configurable but I ran into some issues with  `brotli` decoding and `Req` (the underlying brotli module was failing on the decoding of some sites) so for now have swapped it out with `HTTPoison`.

## UI
The UI is a standard Phoenix LiveView application.

Venue filtering persistence is accomplished via local storage, see the `VenueFilter` hook in `assets/js/app.js` which gets called from `lib/music_listings_web/live/event_live/index.ex`.

## Crawling and Event population
<s>
Events are populated via a nightly [Oban](https://github.com/oban-bg/oban) job.

Event population is initiated via the `lib/music_listings/workers/data_retrieval_worker.ex` Oban job.  The Oban job in turn hands off the population of events to `lib/music_listings/crawler.ex`.  This module performs retrieval, parsing and storage of events.
</s>

Events were previously populated via an Oban job but are now handled via a [Render Cron](https://render.com/docs/cronjobs) job.  See `lib/music_listings/application.ex` for implementation details.  The `crawl_and_exit?` section of `application.ex` starts up the server, runs the crawler and then shuts down the server.

The Oban implementation is still in place but the jobs are not currently being run.  The reason for this change is the crawling takes up a fair bit of memory meaning a larger server instance is required just to run a once nightly job without memory errors.  Moving to a Render Cron job means we can use a cheaper server instance for the main application.

Once event population has concluded an email is sent to the configured `ADMIN_EMAIL` with details of the crawl.  Results are also captured in the `crawl_summaries`, `venue_crawl_summaries` and `crawl_errors` database tables.

The crawler implementation is not very memory efficient.  A list of `payload` structs are built up in memory for each event being parsed.  This might be worth refactoring in the future.

### Parsing modules
The code that performs event parsing for individual venues is located in `lib/music_listings/parsing/venue_parsers`.  Each venue has a parser and parsers implement the `lib/music_listings/parsing/venue_parser.ex` behaviour.

Any errors encountered during parsing will be inserted into the `crawl_errors` database table and included in the aforementioned crawl results email.

### Adding a new venue
In order to track events for a new venue, a new parser for the venue needs to be created at `lib/music_listings/parsing/venue_parsers`.  The venue also needs to be added to the `venues` database table.  Example data files should be added to `test/data` and a test file for the new parser should be added to `test/music_listings/parsing/venue_parsers`.

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
