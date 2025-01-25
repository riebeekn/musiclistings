# MusicListings - .infrastructure - render
This folder contains the Terraform code for performing Render deployments.

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

After apply is run, some outputs will be displayed.  Included in these is an item
to add to the GitHub repository action variables.  It is prefixed with
`github_actions_variable_setting-`.  Likewise there is an item to add to the GitHub repository action secrets.  It is prefixed with `github_actions_secret_setting-`.

The following outputs are expected:
```
application_url = "<the url of the application, i.e. https://staging.torontomusiclistings.com">

db_connection_info = "<the connection information for the database>"

github_actions_secret_setting-ENV_DEPLOY_HOOK = "include a deploy hook secret for the current environment, name the secret <ENV>_DEPLOY_HOOK and set it to the deploy hook url in the service settings See https://dashboard.render.com/web/srv-cu5ut6l6l47c73bt7vog/settings, the hook is not available programmatically thus why this has to be done manually"

github_actions_variable_setting-RENDER_ENVIRONMENTS = "include the current environment which is: <something like staging:src-123343>"
```

As per the above a `<ENV>_DEPLOY_HOOK` secret needs to be set in GitHub where `<ENV>` is replaced by the current environment (for example `STAGING_DEPLOY_HOOK`, `PROD_DEPLOY_HOOK` etc.).  The value of this needs to be retrieved manually from the Render Dashboard for the created web service as the value is not available from Terraform.

Likewise each environment should be added to a RENDER_ENVIRONMENTS GitHub actions variable and they are comma separated.
So for example the value of this variable could be `staging:src-123343,qa:src-123344,production:src-123345`.

Add the GitHub repository action variable and the secret at the following URL:
https://the_github_repo_url/settings/variables/actions.

### To destroy the infrastructure

```
./tf_destroy.sh
```
