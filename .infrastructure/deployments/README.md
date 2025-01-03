# MusicListings - .infrastructure - deployments
This folder contains the Terraform code for performing deployments.

It is dependent on the core infrastructure being provisioned, see the `core`
folder for more information.

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

Now create or update the environment specific `terraform.tfvars` file.  As per
the workspace we've selected above (staging) you would create or update the
`staging.tfvars` file.  See `staging.tfvars.example` for an example.

Access to the deployed application can be restricted via basic auth.  To enable
this enter values for the `basic_auth_username` and `basic_auth_password` in the
`.tfvars` file.  This will result in a CloudFlare worker being deployed which
will prompt for the username and password before allowing access to the site.

Instead of natively running terraform apply, plan, and destroy commands use the
`tf_apply.sh`, `tf_plan.sh`, and `tf_destroy.sh` scripts respectively.  These
automatically pick up the environment specific `.tfvars` based on the
current workspace.

### To bring up the infrastructure

```
./tf_apply.sh
```

After apply is run, some outputs will be displayed.  These will include items
to add to the GitHub repository action variables.  These are prefixed with
`github_actions_variable_setting-`.

The following outputs are expected:
```
github_actions_variable_setting-AWS_ACCOUNT_ID = "<an account id>"
github_actions_variable_setting-AWS_BUILD_ROLE = "<build arn>"
github_actions_variable_setting-AWS_ECR_REPO = "<ecr repo name>"
github_actions_variable_setting-AWS_ENVIRONMENTS = "include the current environment which is: 'staging'"
github_actions_variable_setting-AWS_REGION = "<the aws region>"
github_actions_variable_setting-AWS_SERVICE_NAME_PREFIX = "<the service prefix>"
```

Add these to the GitHub repository action variables at the following URL:
https://<the github repo url>/settings/variables/actions.

Once set these variables do not need to be updated when additional deployments
or environments are set up.

**NOTE:** the exception to this is the `AWS_ENVIRONMENTS` variable.  This should
include a comma separated list of all environments.  So for example, if you have
only a staging environment, the value should be `staging`.  If you have staging,
qa and production environments, the value should be `staging,qa,production`.

### To destroy the infrastructure

```
./tf_destroy.sh
```
