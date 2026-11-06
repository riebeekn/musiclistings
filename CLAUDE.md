# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **MusicListings**, a Phoenix LiveView application that aggregates music event listings for the Toronto area. The app crawls various venue websites to collect and display upcoming concerts and events at [torontomusiclistings.com](https://torontomusiclistings.com).

## Tech Stack

- **Elixir** ~> 1.14
- **Phoenix Framework** ~> 1.7.14
- **Phoenix LiveView** ~> 1.1
- **PostgreSQL** database with Ecto
- **Tailwind CSS** for styling
- **Oban** for background jobs (though crawling now uses Render Cron)
- **Deployment**: Render

## Common Development Commands

### Setup and Development
```bash
# Install dependencies
mix deps.get

# Setup database (create, migrate, seed)
mix ecto.setup

# Start Phoenix server with IEx
iex -S mix phx.server

# Reset database
mix ecto.reset

# Run migrations
mix ecto.migrate
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/music_listings/parsing/venue_parsers/phoenix_parser_test.exs

# Run with coverage
mix coveralls.html
```

### Code Quality
```bash
# Format code
mix format

# Run linter with strict mode
mix credo --strict

# Run dialyzer for type checking
mix dialyzer

# Full check (format, credo, compile with warnings, dialyzer, docs)
mix check
```

### Assets
```bash
# Build assets for development
mix assets.build

# Deploy assets for production
mix assets.deploy
```

## Architecture Overview

### Core Domain Structure

The application follows a modular architecture with clear separation of concerns:

1. **Web Layer** (`lib/music_listings_web/`)
   - LiveView modules for real-time UI (`live/`)
   - Components for reusable UI elements (`components/`)
   - Router defining all application routes
   - User authentication via phx.gen.auth

2. **Business Logic** (`lib/music_listings/`)
   - **Crawler Module**: Orchestrates web scraping and event storage
   - **Events Context**: Manages event queries and business logic
   - **Venues Context**: Handles venue data and relationships
   - **Parsing System**: Modular venue-specific parsers

3. **Data Layer** (`lib/music_listings_schema/`)
   - Ecto schemas for database entities
   - Events, Venues, CrawlSummaries, SubmittedEvents

### Parsing System Architecture

The parsing system is highly modular with a clear hierarchy:

- **VenueParser behaviour** defines the contract all parsers must implement
- **Base Parsers** (`lib/music_listings/parsing/venue_parsers/base_parsers/`) provide reusable parsing logic for common platforms (LiveNation, SquareSpace, WordPress, etc.)
- **Venue-Specific Parsers** inherit from base parsers or implement custom logic
- Each parser returns a list of `Payload` structs containing parsed event data

### Key Workflows

1. **Event Crawling**:
   - Triggered via Render Cron job (see `lib/music_listings/application.ex`)
   - `Crawler` module fetches data from each venue
   - Venue-specific parsers extract event information
   - Events are stored/updated in database
   - Email summary sent to admin

2. **Event Display**:
   - LiveView pages at `/events` and `/events/venue/:venue_id`
   - Real-time filtering by venue using JavaScript hooks
   - Venue preferences stored in localStorage

3. **Event Submission**:
   - Users can submit events via `/events/new`
   - Admin approval required (accessible when logged in)

## Environment Variables

Key environment variables (set in `.envrc` from `.envrc_template`):
- `ADMIN_EMAIL`: Receives crawl summaries and submission notifications
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY_BASE`: Phoenix secret key
- `TURNSTILE_SITE_KEY` / `TURNSTILE_SECRET_KEY`: Cloudflare Turnstile for spam protection
- `BREVO_API_KEY`: Email service configuration

## Adding New Venues

To add support for a new venue:

1. Create parser at `lib/music_listings/parsing/venue_parsers/[venue_name]_parser.ex`
2. Implement the `VenueParser` behaviour
3. Add venue to database via migration in `priv/repo/migrations/`
4. Add test data in `test/data/[venue_name]/`
5. Create test file at `test/music_listings/parsing/venue_parsers/[venue_name]_parser_test.exs`

### Important information regarding adding a new venue
1. If events are recurring and have a duplicate ID, use a combination of the venue name and event date as the event_id so that recurring events are inserted for all the appropriate dates. The ParseHelpers module contains `build_id_from_venue_and_date` and `build_id_from_venue_and_datetime` functions for this purpose.
2. When adding the migration for the new venue populate the `google_map_url` value with the URL for the google map venue, the URL should include a pin marker for the venue.
3. When browsing a venue's site be mindful of rate limits and do not hammer the site with requests!
4. `MusicListings.Crawler.crawl` can be called passing in a list just containing the new venue to check that the crawler executes correctly.

## Venues Render Can't Reach

Some venues' origin servers silently drop Render's egress IP at the TCP layer, so the nightly
crawl can never reach them — the connection times out before a single HTTP byte is sent
(`%Req.TransportError{reason: :timeout}`). This is **not** fixable in a parser: no header,
user-agent, or retry helps, because the origin never completes the TCP handshake. Confirmed from
an IEx session on Render, where `:gen_tcp.connect` to the origin hangs on IPv4 while a reachable
host connects instantly.

Currently affected: **Wiggle Room** and **Junction Underground** (both on the same Hostinger box,
`195.35.15.150`).

These sites *are* reachable from a home/residential connection, so crawl them locally instead.
Venues are identified by their `parser_module_name`, not their id — ids are assigned per
environment, so a command written by prod would point at the wrong venue locally:

```bash
./bin/crawl-venue.sh WiggleRoomParser
./bin/crawl-venue.sh WiggleRoomParser JunctionUndergroundParser
```

This runs `mix crawl_venue` with `USE_PROD_DB=true`, which points the dev app at the production
database via `$PROD_DB_URL` (see `config/dev.exs`) so the results land in prod, and emails a
"Local Crawl Report" to `$ADMIN_EMAIL` via Brevo (`$BREVO_API_KEY` required) just like the nightly
crawl does. The nightly crawl summary email prints the exact command for any venue that logged a
`fetch_error` (a timeout, other transport failure, or non-200 status). Venues that were fetched but
listed nothing get a `no_events_error` instead and are left out of the command — that's usually a
seasonal venue or a broken parser, and crawling locally won't help. A parser that crashes on the
page itself logs a `page_parse_error`.

## Venues Behind a Cloudflare Challenge

**Massey Hall, Roy Thomson Hall and TD Music Hall** (`*.mhrth.com`) sit behind a Cloudflare Managed
Challenge keyed on bot score. Erlang's `:ssl` TLS fingerprint is classed as automated, so Finch/Req
gets a `403` challenge page (`cf-mitigated: challenge`) whatever the headers. The IP counts too: a
real Chrome fingerprint (curl-impersonate) gets through from a residential IP but not from Render's.
`MhRthTdmhParser` therefore makes all of its requests with `HttpClient.get(url, [], firecrawl: true)`,
which has Firecrawl (`MusicListings.HttpClient.Firecrawl`) load the page in a real browser on its own
IPs and return the rendered HTML.

- `$FIRECRAWL_API_KEY` (Render env via the `app_firecrawl_api_key` Terraform variable; `.envrc`
  locally) authenticates the requests. It's optional - Firecrawl also serves unauthenticated
  requests - but set it for the nightly crawl. Each request is 1 Firecrawl credit.
- The response's `status` is the *target's* (Firecrawl's `metadata.statusCode`), so a challenged
  page is still a `403`. Firecrawl doesn't pass request headers on.
- Listing card links come back as full URLs from a rendered page (paths from a plain fetch);
  `MhRthTdmhParser.details_url/1` reduces either to the path, as stored events are matched on it.
- The listing has each event's dates but no times or ticket links. Those come from the event's
  details page, where the site's `<instance-list>` widget renders them from
  `/api/attendable/v1/instances/` - so they're only in the HTML because the page is rendered
  (`MhRthTdmhParser.showings/1`). Don't call that API directly: it needs
  `accept: application/json` (otherwise it picks its HTML renderer and `500`s), which Firecrawl
  can't send. The widget hides past showings, only shows a time for a showing with an end time,
  and only links a showing while it's on sale, so a looked-up time or ticket link can be `nil`.
- A burst of requests can still draw the challenge, so `MhRthTdmhParser` parses one event at a
  time (the optional `max_concurrency/0` parser callback) and pauses before every request
  (`:mhrth_request_interval_ms`, 6s by default - which also keeps the crawl under Firecrawl's
  10 requests/min free-plan scrape limit - 0 in test). A `403` trips
  `MusicListings.Parsing.ChallengeBreaker`, and `MhRthTdmhParser` skips its follow-up lookups
  until a listing page gets through again (the skipped events are reported as lookup failures).
- Every request counts toward the challenge (and costs a credit), so the parser only follows
  pages the listing links to (requesting past the last page returns that page's events again),
  and implements the optional `dedupe_key/1` callback so an event listed twice is parsed, and
  looked up, once. `dedupe_key/1` must not make a request - the crawler calls it on every event
  before parsing.
- An event whose listing dates are already stored with ticket links (matched on `details_url`) skips
  its follow-up lookup and reuses the stored dates, times and links; only new events, new dates,
  and dates still missing a link are looked up.
- A follow-up lookup that fails is reported via `MusicListings.Parsing.LookupFailures`. The crawl
  report then shows a `lookup_error` for the venue, and `EventStorage` keeps the stored ticket
  link/time instead of overwriting them with `nil`. Any parser whose follow-up requests can fail
  should record its failures the same way.
- A curl-impersonate HTTP client used to fetch these venues. It was removed because it can't get
  through from Render's IP; it's in git history (added in `3f6e020`) if ever needed for local crawls.

## Venues Behind a SiteGround Challenge

**Linsmore Tavern** is hosted on SiteGround, which answers requests from Render's IP with a `202`
whose body redirects to a proof-of-work challenge (`/.well-known/sgcaptcha/`). The block looks
IP-based: the same request gets a `200` from a home connection. Headers, retrying on `202`, and a
home-grown solver were all tried and reverted (`e194eb9`) - the solver found valid solutions, but the
re-fetched page was just a new challenge. `LinsmoreParser` therefore fetches through Firecrawl
(`firecrawl: true`), about 1 credit a night. If a nightly crawl reports a `fetch_error` for it, Firecrawl
got challenged or failed that night; `./bin/crawl-venue.sh LinsmoreParser` is the fallback.

## Lee's Palace and The Dance Cave

The Dance Cave is upstairs at Lee's Palace. Lee's calendar (`LeesPalaceParser`) lists both rooms and
`DanceCaveParser` gets the upstairs shows from Live Nation, so most Dance Cave shows are crawled
twice. Neither source can be dropped: each has shows the other lacks, and only Live Nation has times.
After each crawl `Curation.remove_redundant_room_listings/0` soft-deletes the Lee's side of any open
duplicate flag between the two, dismisses the flag, and the crawl email lists the removal. Clearing a
listing's `deleted_at` restores it for good, since only open flags are acted on. A listing with
`locked_from_updates` set is left for manual review. `mix curate_events` doesn't remove anything.

## Database Operations

### Common Ecto Commands
```elixir
# In IEx console
alias MusicListings.{Repo, Events, Venues}
alias MusicListingsSchema.{Event, Venue, SubmittedEvent}

# Query examples
Venues.list_venues()
Events.list_events()
Repo.get(Venue, venue_id)

# Manual crawl trigger
MusicListings.Workers.DataRetrievalWorker.perform(%{})
```

### Admin User Creation
```elixir
# Create admin user (in IEx)
MusicListings.Accounts.register_user(%{
  email: "admin@example.com",
  password: "secure_password"
})
```

## Testing Approach

- Comprehensive unit tests for all parsers using local HTML fixtures
- Integration tests for LiveView components
- Factory-based test data generation with ExMachina
- Coverage reporting with ExCoveralls

## Deployment Notes

- Application deploys automatically to Render via GitHub Actions
- Infrastructure managed via Terraform (`.infrastructure/` directory)
- Uses CloudFlare as reverse proxy

### Terraform Variables (1Password)

- The Render module's per-workspace Terraform variables are stored in 1Password as
  Secure Note items named `<workspace>.tfvars` (e.g. `staging.tfvars`, `prod.tfvars`).
  The `.infrastructure/render/tf_plan.sh`, `tf_apply.sh`, and `tf_destroy.sh` scripts
  pull them at runtime (via `tf_common.sh`) into a temp file that is deleted on exit —
  they are never written to git or kept on disk. The 1Password account and vault are
  supplied via `OP_ACCOUNT`/`OP_VAULT` exported from the gitignored `.envrc` (see
  `.infrastructure/render/.example.envrc`), so they stay out of this public repo.
- **IMPORTANT: Claude must NEVER execute any Terraform commands** — not
  `terraform plan/apply/destroy`, nor the `tf_*.sh` wrappers, nor any other command
  that runs Terraform.

## Feature Flags

Feature flags use [FunWithFlags](https://github.com/tompave/fun_with_flags), persisted via Ecto
(table `feature_flags`) with the in-memory cache **disabled** (config in `config/config.exs`).
Check a flag once per request and reuse the boolean — don't call `FunWithFlags.enabled?/1` in a loop.

## Important Patterns

1. **Error Handling**: Parse errors are captured in `crawl_errors` table and included in admin emails
2. **Memory Management**: Crawling builds payloads in memory - be mindful of venue count
3. **HTTP Client**: Configurable via `config :music_listings, :http_client`
4. **LiveView Hooks**: Venue filter persistence uses JavaScript hooks in `assets/js/app.js`

## Development Workflow

1. Always run `mix check` after all changes have been made and fix any warnings
2. Always run `mix test` after all changes have been made and ensure all the tests pass
