# cloudflare.tf
# Contains the Terraform code to create the Cloudflare resources
# for the application. This includes the DNS record, Origin certificate
# and basic auth worker

# DNS Record
resource "cloudflare_record" "this" {
  zone_id = var.cloudflare_zone_id
  name    = var.environment
  content = aws_lb.this.dns_name
  type    = "CNAME"
  proxied = true
}

# Origin Certificate
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "tls_cert_request" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "${var.environment}.torontomusiclistings.com"
    organization = "Your Organization Name"
  }
}

resource "cloudflare_origin_ca_certificate" "this" {
  csr                = tls_cert_request.this.cert_request_pem
  hostnames          = ["${var.environment}.torontomusiclistings.com"]
  request_type       = "origin-rsa"
  requested_validity = 7
}

resource "aws_acm_certificate" "cert" {
  certificate_body = cloudflare_origin_ca_certificate.this.certificate
  private_key      = tls_private_key.this.private_key_pem
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
