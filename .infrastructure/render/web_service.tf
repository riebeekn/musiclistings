# Generate a random secret key base
resource "random_password" "secret_key_base" {
  length  = 64
  special = true
  numeric = true
  upper   = true
  lower   = true
}

resource "render_web_service" "this" {
  name           = "${local.name}-web-service"
  plan           = var.render_web_service_plan
  region         = var.render_region
  environment_id = render_project.this.environments["default"].id
  runtime_source = {
    docker = {
      branch      = var.initial_branch_to_deploy
      repo_url    = "https://github.com/${var.github_repository}"
      auto_deploy = false
    }
  }
  health_check_path = "/health_check"
  custom_domains = [
    { name : var.app_domain }
  ]
  env_vars = {
    "ADMIN_EMAIL" = {
      value = var.app_admin_email
    },
    "BREVO_API_KEY" = {
      value = var.app_brevo_api_key
    },
    "TURNSTILE_SECRET_KEY" = {
      value = var.app_turnstile_secret_key
    },
    "TURNSTILE_SITE_KEY" = {
      value = var.app_turnstile_site_key
    },
    "SECRET_KEY_BASE" = {
      value = random_password.secret_key_base.result
    },
    "PULL_DATA_FROM_WWW" = {
      value = "true"
    },
    "DATABASE_URL" = {
      value = render_postgres.this.connection_info.internal_connection_string
    },
    "PHX_HOST" = {
      value = var.app_domain
    }
  }
}
