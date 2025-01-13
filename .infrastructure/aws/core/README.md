# MusicListings - .infrastructure - aws - core
This folder contains the Terraform code for the core project infrastructure.

This includes resources shared across environments such as the ECR repository, GitHub action
build permissions and roles, and AWS secrets.

Set up this infrastructure prior to running the `deployments` Terraform code
as the `deployments` Terraform code depends on the core infrastructure being provisioned
and indeed references it via remote state.

Everything has been marked with a `prevent_destroy = true` lifecycle rule as it is
expected that these resources will not be destroyed.

## Executing the Terraform code
Copy the `terraform.tfvars.example` file to `terraform.tfvars` and update the values
as appropriate.

The `app_brevo_api_key`, `app_turnstile_site_key`, and `app_turnstile_secret_key` values
can be left blank if not wanting to engage this functionality, see
`variables.tf` for more information.

### To bring up the infrastructure

```
terraform apply
```

### To destroy the infrastructure
This will require updating / removing the `prevent_destroy = true` lifecycle attributes.

```
terraform destroy
```
