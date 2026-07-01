# MusicListings - .infrastructure - render
This folder contains the Terraform code for performing Render deployments.

## Bringing up a new environment
A quick checklist for standing up a new environment (e.g. a fresh `staging`).  Each
step is expanded on in the sections below.

1. Complete the [Prerequisites](#prerequisites) (`.envrc`, 1Password CLI, and a
   `<workspace>.tfvars` note for the new environment).
2. Create/select the Terraform workspace for the environment, e.g.
   `terraform workspace new staging`.
3. Run `./tf_apply.sh` to provision the Render web service, cron job, database, and
   CloudFlare records.
4. From the apply outputs, append the new environment to the `RENDER_ENVIRONMENTS`
   (`<env>:srv-…`) and `RENDER_CRON_ENVIRONMENTS` (`<env>:crn-…`) GitHub Actions
   **variables** — comma-separated.  These service IDs are what tell CI which
   services to deploy to; the deploy matrix fans out one job per entry.
5. Ensure the account-level `RENDER_API_KEY` GitHub Actions **secret** is set (one
   time, shared across all environments — no per-environment secret is needed).

That's it — CI will now deploy the new environment via the Render REST API.  `prod`
only deploys from `main`; other environments deploy from any branch.

## Prerequisites

1. **Environment (`.envrc`)** — copy `.example.envrc` to `.envrc`, fill in the
   values, and `source .envrc` (or use [direnv](https://direnv.net/)).  This exports
   the AWS credentials (the Terraform state lives in an S3 backend,
   `terraform-render-musiclistings-state`) plus `OP_ACCOUNT` and `OP_VAULT`, which
   tell the scripts which 1Password account and vault to read the variables from.
2. **1Password CLI** — the environment-specific Terraform variables are stored in
   1Password, not in local files.  Install the CLI (`brew install 1password-cli`)
   and enable desktop-app integration (1Password app → Settings → Developer →
   "Integrate with 1Password CLI").  In the account/vault configured via `.envrc`,
   create a Secure Note item per workspace named `<workspace>.tfvars` (e.g.
   `staging.tfvars`, `prod.tfvars`) whose note body holds the `.tfvars` contents.
   See `variables.tf` for the full list of variables.

## Executing the Terraform code
It is expected that the deployments will be executed against a particular
Terraform workspace, so the first step is to switch to or create the workspace.

For example:
```
terraform create workspace new staging
```

Or if the workspace already exists:
```
terraform workspace select staging
```

The environment-specific variables are stored in 1Password (the vault configured
via `OP_VAULT` in `.envrc`) as a Secure Note named `<workspace>.tfvars`.  As per
the workspace we've selected above (staging) the variables come from the
`staging.tfvars` item.  To update them, edit that item's note body in 1Password.
See `variables.tf` for the full list of variables.

Access to the deployed application can be restricted via basic auth.  To enable
this enter values for the `basic_auth_username` and `basic_auth_password` in the
1Password note.  This will result in a CloudFlare worker being deployed which
will prompt for the username and password before allowing access to the site.

Instead of natively running terraform apply, plan, and destroy commands use the
`tf_apply.sh`, `tf_plan.sh`, and `tf_destroy.sh` scripts respectively.  These
fetch the environment-specific variables live from the 1Password `<workspace>.tfvars`
item (into a temp file that is deleted on exit) based on the current workspace, so
nothing sensitive is written to disk.

### To bring up the infrastructure

```
./tf_apply.sh
```

After apply is run, some outputs will be displayed.  Included in these are two items
to add to the GitHub repository action variables.  They are prefixed with
`github_actions_variable_setting-`.

The following outputs are expected:
```
application_url = "<the url of the application, i.e. https://staging.torontomusiclistings.com">

db_connection_info = "<the connection information for the database>"

github_actions_variable_setting-RENDER_ENVIRONMENTS = "include the current environment which is: <something like staging:src-123343>"

github_actions_variable_setting-RENDER_CRON_ENVIRONMENTS = "include the current environment which is: <something like staging:crn-123343>"
```

Deploys are triggered from GitHub Actions via the Render REST API, which authenticates
with a `RENDER_API_KEY` GitHub Actions secret.  This is an account-level key (not per
environment) and is not produced by Terraform - create it once from the Render dashboard
(Account Settings → API Keys) and add it as a repository secret.

Each environment should be added to a RENDER_ENVIRONMENTS GitHub actions variable and they are comma separated.
So for example the value of this variable could be `staging:src-123343,qa:src-123344,production:src-123345`.

Do the same and add each environment to a RENDER_CRON_ENVIRONMENTS GitHub actions variable, again they are comma separated.
So for example the value of this variable could be `staging:crn-123343,qa:crn-123344,production:crn-123345`.

Add the GitHub repository action variables at the following URL:
https://the_github_repo_url/settings/variables/actions.  Add the `RENDER_API_KEY`
secret at https://the_github_repo_url/settings/secrets/actions.

### To destroy the infrastructure

```
./tf_destroy.sh
```
