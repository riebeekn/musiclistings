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
