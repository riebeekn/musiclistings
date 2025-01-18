output "application_url" {
  value = "https://${cloudflare_record.this.hostname}"
}

output "db_connection_info" {
  value     = render_postgres.this.connection_info
  sensitive = true
}

output "github_actions_variable_setting-RENDER_ENVIRONMENTS" {
  value       = "include the current environment which is: ${var.environment}:${render_web_service.this.id}"
  description = <<EOF
    "The current environment - include this as part of the RENDER_ENVIRONMENTS GHA variable, i.e. staging:srv-1234...
    if you have multiple environments use a comma separated list, such as staging, qa"
  EOF
}

output "github_actions_secret_setting-ENV_DEPLOY_HOOK" {
  value = "include a deploy hook secret for the current environment, name the secret ${upper(var.environment)}_DEPLOY_HOOK and set it to the deploy hook url in the service settings See https://dashboard.render.com/web/${render_web_service.this.id}/settings, the hook is not available programmatically thus why this has to be done manually"

  description = <<EOF
    "The deploy hook for the current environment - add this as a GHA secret, i.e. name the secret STAGING_DEPLOY_HOOK...
    then get the value from the Render dashboard settings

    The value is not available programitically, thus the value needs to be retrieved manually"
  EOF
}
