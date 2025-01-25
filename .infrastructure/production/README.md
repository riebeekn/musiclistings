# MusicListings - .infrastructure - production
This Terraform project represents existing production infrastructure that was created
manually with initial deployment to Fly.io and has now been imported into Terraform.

Resources imported:

- Some DNS Settings
- Turnstile Widget

Not everything has been imported, email forwarding settings, which in turn create the
MX DNS records have not been imported.

Everything has been marked with a `prevent_destroy = true` lifecycle rule as none of these
resources should be destroyed.

## Executing the Terraform code
Running an apply will result in no changes unless we make an actual change to
one of the tfvar values as this project just reflects the existing production DNS and Turnstile
settings.

Copy the `terraform.tfvars.example` file to `terraform.tfvars` and update the values
as appropriate.

### To bring up the infrastructure

```
terraform apply
```

### To destroy the infrastructure
This will require updating / removing the `prevent_destroy = true` lifecycle attributes.

```
terraform destroy
```
