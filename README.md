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
  - [AWS Remote access](#aws-remote-access)
    - [Database](#database)
    - [IEX](#iex)
    - [Trouble shooting](#trouble-shooting)
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
    - `PULL_DATA_FROM_WWW` - if true will scrape events from the web, when false will use the local files located in `/test/data`.
- Run the server (`iex -S mix phx.server`).  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
- Events are populated via an Oban Job at 7am UTC.
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
Events are populated via a nightly [Oban](https://github.com/oban-bg/oban) job.

Event population is initiated via the `lib/music_listings/workers/data_retrieval_worker.ex` Oban job.  The Oban job in turn hands off the population of events to `lib/music_listings/crawler.ex`.  This module performs retrieval, parsing and storage of events.

Once event population has concluded an email is sent to the configured `ADMIN_EMAIL` with details of the crawl.  Results are also captured in the `crawl_summaries`, `venue_crawl_summaries` and `crawl_errors` database tables.

The crawler implementation is not very memory efficient.  A list of `payload` structs are built up in memory for each event being parsed.  This might be worth refactoring in the future.

### Parsing modules
The code that performs event parsing for individual venues is located in `lib/music_listings/parsing/venue_parsers`.  Each venue has a parser and parsers implement the `lib/music_listings/parsing/venue_parser.ex` behaviour.

Any errors encountered during parsing will be inserted into the `crawl_errors` database table and included in the aforementioned crawl results email.

### Adding a new venue
In order to track events for a new venue, a new parser for the venue needs to be created at `lib/music_listings/parsing/venue_parsers`.  The venue also needs to be added to the `venues` database table.  Example data files should be added to `test/data` and a test file for the new parser should be added to `test/music_listings/parsing/venue_parsers`.

## Hosting and Infrastructure
The application is currently hosted on [fly.io](https://fly.io/).

I've been experimenting with various hosting platforms and strategies, so there are implementations for [Render](https://render.com/) and [AWS](https://aws.amazon.com) as well.  The decision to use AWS was more as a learning exercise, and it isn't very cost effective for a hobby application so for now am sticking with `fly`.  I'm sure I could reduce costs by re-architecting the application and / or infrastructure set-up.  As things stand, approximate daily costs for `AWS` seem to be:

| Service                      | Cost      |
| ---------------------------- | --------- |
| VPC                          |   $2.28   |
| Elastic Load Balancing       |   $0.54   |
| Relational Database Service  |   $0.45   |
| Elastic Container Service    |   $0.35   |
| EC2-Instances                |   $0.20   |
| Secrets Manager              |   $0.06   |
| EC2-Other                    |   $0.02   |
| **Total**                    | **$3.90** |

I am likely to permanently move to `Render` as I like that I can use Terraform with it.

The `fly.io`, `Render` and `AWS` solutions use CloudFlare as a reverse proxy.

Deployment and infrastructure setup is handled by a combination of Terraform and GitHub Actions.  Unfortunately `fly.io` does not have a Terraform provider so the `fly` infrastructure was set up manually.

### GitHub Actions
GitHub actions control deployments and are located in `.github/workflows/ci.yml`.  Since we have the ability to deploy to multiple hosts (fly, Render and AWS) the deployment actions are dependent on 3 corresponding GitHub Action variables:

- `DEPLOY_TO_AWS`: if set to true GHA will attempt to deploy to AWS
- `DEPLOY_TO_FLY`: if set to true GHA will attempt to deploy to Fly
- `DEPLOY_TO_RENDER`: if set to true GHA will attempt to deploy to Render

All (or none) of these variables can be set, they are not mutually exclusive.

### Terraform
There are 4 Terraform projects which serve the following purposes:
- `.infrastructure/aws/core` - Contains the core AWS infrastructure which is shared across different environments (i.e. staging, prod etc.).
- `.infrastructure/aws/deployments` - Contains environment specific AWS infrastructure, for example `qa`, `staging`, or `prod` infrastructure.
- `.infrastructure/production` - Represents production infrastructure that was set up manually and has since been imported into Terraform.
- `.infrastructure/render` - Contains Render specific infrastructure files.

See the `README.md` files located in each of the projects for specific information on running the Terraform deployments.  In general the `production` project should never need to be run.  With AWS, the `core` project needs to be run once to bring up the shared infrastructure, and then the `deployments` project can be run as needed.

The AWS Terraform setup is largely based on this excellent example Repo: [https://github.com/danschultzer/elixir-terraform-aws-ecs-example](https://github.com/danschultzer/elixir-terraform-aws-ecs-example).

### AWS Remote access
Remote access to the database and local `iex` sessions are accomplished via `ssm` and `aws ecs execute-command`.  Helper scripts are available to make it easy to connect.

#### Database
To access the database for an environment run the `.db_tunnel.sh` script passing in the name of environment you would like to connect to, for example:

```
./db_tunnel.sh staging
```

This will result in output similar to:
```
Starting session with SessionId: terraform-user-2ft5jzhcckusb5zeo29gdarfke
Port 5433 opened for sessionId terraform-user-2ft5jzhcckusb5zeo29gdarfke.
Waiting for connections..
```

You can now connect with your local database client.  You will need to retrieve the database password.  This can be done from the `.infrastructure/deployments` directory.  Make sure you are in the correct workspace and then run:

```
terraform output -raw db_instance_password
```

This will output the database password.  I.e. something similar to:

```
➜  deployments git:(main) ✗ terraform output -raw db_instance_password
%5jw#1Lz$of}D)>th0dMmtlhlo3ZZM>O%
```

**Note:** exclude the `%` at the end of the string, not sure why that is added to the output on the terminal.  Piping to a text file, i.e. `terraform output -raw db_instance_password > db_pass.txt` does not add the extra `%`.

Now connect with the following parameters:

```
Host: 127.0.0.1
Port: 5433
User: the user you set up in the Terraform deployment
Password: the password output from above
```

#### IEX
To run an `iex` session against a deployed environment run the `aiex.sh` script passing in the name of the environment you would like to connect to, for example:

```
./aiex.sh staging
```

You'll now have an `iex` session on the environment.

See the details of the `aiex.sh` script if wanting to do something other than open an `iex` session.  For instance if just wanting to run a shell, change the `Execute the command on the ECS container` command, i.e. instead of this:

```
# Execute the command on the ECS container
aws ecs execute-command \
  --cluster "${ECS_CLUSTER_NAME}" \
  --task "${AWS_TASK_ID}" \
  --container "${CONTAINER_NAME}" \
  --interactive \
  --command "/bin/sh -c 'bin/music_listings remote'"
```

Do this:

```
# Execute the command on the ECS container
aws ecs execute-command \
  --cluster "${ECS_CLUSTER_NAME}" \
  --task "${AWS_TASK_ID}" \
  --container "${CONTAINER_NAME}" \
  --interactive \
  --command "/bin/sh
```

#### Trouble shooting
Remote access requires specific settings both locally (you need the AWS CLI installed along with AWS SSM) and on the server (a NAT gateway and enable_remote_execution enabled on the ECS service).

There is handy check command available.  First determine the task id of the AWS task you are attempting to connect to, i.e.

```
aws ecs list-tasks --cluster "musiclistings-staging"
```

This will output something similar to:

```
{
    "taskArns": [
        "arn:aws:ecs:<region>:<aws account id>:task/musiclistings-staging/<task id>"
    ]
}
```

Now run:

```
bash <( curl -Ls https://raw.githubusercontent.com/aws-containers/amazon-ecs-exec-checker/main/check-ecs-exec.sh ) musiclistings-staging <task id>
```

This will present information regarding whether you have remote access.

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
PULL_DATA_FROM_WWW=$PULL_DATA_FROM_WWW \
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
  --env PULL_DATA_FROM_WWW=$PULL_DATA_FROM_WWW \
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
