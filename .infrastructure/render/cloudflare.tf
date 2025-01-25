# cloudflare.tf
# Contains the Terraform code to create the Cloudflare resources
# for the application. This includes the DNS record
# and basic auth worker

# DNS Record
resource "cloudflare_record" "root_cname" {
  zone_id = var.cloudflare_zone_id
  # in prod use root, in other environments use the environment name
  name    = var.environment == "prod" ? "@" : var.environment
  content = replace(render_web_service.this.url, "https://", "")
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "www_cname" {
  # only create the www record in prod
  count   = var.environment == "prod" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content = replace(render_web_service.this.url, "https://", "")
  type    = "CNAME"
  proxied = true
}

# Basic Auth Worker
resource "cloudflare_workers_script" "basic_auth_script" {
  count      = length(var.basic_auth_username) > 0 && length(var.basic_auth_password) > 0 ? 1 : 0
  name       = "basic-auth"
  account_id = var.cloudflare_account_id
  content = templatefile("${path.module}/basic_auth_worker_template.js", {
    username = var.basic_auth_username,
    password = var.basic_auth_password
  })
}

# Runs the specified worker script for all URLs that match the pattern
resource "cloudflare_workers_route" "this" {
  count       = length(var.basic_auth_username) > 0 && length(var.basic_auth_password) > 0 ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  pattern     = "${var.environment}.torontomusiclistings.com/*"
  script_name = cloudflare_workers_script.basic_auth_script[0].name
}
