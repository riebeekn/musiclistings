# MusicListings - .infrastructure - production
This Terraform project represents existing production infrastructure that was created
manually with initial deployment to Fly.io and has now been imported into Terraform.

It is separate from `.infrastructure/render`, and much simpler: no workspaces, no
1Password, no wrapper scripts - just `terraform` run directly with a local
`terraform.tfvars`.  In normal operation you should never need to run it.

Resources imported (see `cloudflare_dns.tf` and `cloudflare_turnstile.tf`):

- CloudFlare DNS records for email: `DMARC`, `DKIM`, `SPF` and the Brevo verification
  `TXT` record.
- The CloudFlare Turnstile widget used by the event submission and contact forms.

Not everything has been imported, email forwarding settings, which in turn create the
MX DNS records have not been imported.  The application's own DNS records are **not** here
either - the CNAME pointing at the Render web service (and, in prod only, the `www` CNAME)
is created per environment by `.infrastructure/render/cloudflare.tf`.

Everything has been marked with a `prevent_destroy = true` lifecycle rule as none of these
resources should be destroyed.

## Prerequisites

1. **Environment (`.envrc`)** — copy `.example.envrc` to `.envrc`, fill in the AWS
   credentials, and `source .envrc` (or use [direnv](https://direnv.net/)).  These are
   needed for the S3 state backend, `terraform-musiclistings-state` (see `backend.tf`) —
   note this is a *different* bucket to the one the render project uses.
2. **Variables (`terraform.tfvars`)** — copy `terraform.tfvars.example` to
   `terraform.tfvars` and fill in the values (CloudFlare account/zone/API token plus the
   email record contents).  Unlike the render project these are read from a local file,
   so `terraform.tfvars` is gitignored and must not be committed.  See `variables.tf`
   for the full list.

## Executing the Terraform code
Running an apply will result in no changes unless we make an actual change to
one of the tfvar values as this project just reflects the existing production DNS and Turnstile
settings.

### To bring up the infrastructure

```
terraform apply
```

### To destroy the infrastructure
This will require updating / removing the `prevent_destroy = true` lifecycle attributes.

```
terraform destroy
```
