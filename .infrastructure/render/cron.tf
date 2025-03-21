resource "render_cron_job" "this" {
  name           = "${local.name}-crawler"
  plan           = var.render_cron_service_plan
  region         = var.render_region
  environment_id = render_project.this.environments["default"].id
  runtime_source = {
    docker = {
      branch      = var.branch_to_deploy_for_cron_service
      repo_url    = "https://github.com/${var.github_repository}"
      auto_deploy = false
    }
  }
  schedule      = var.render_cron_service_schedule
  start_command = "bin/music_listings start"

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
    "CRAWL_AND_EXIT" = {
      value = "true"
    }
  }
}
