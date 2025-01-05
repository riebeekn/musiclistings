# secrets.tf
# Contains the Terraform code to create the required secrets in AWS Secrets Manager

resource "aws_secretsmanager_secret" "brevo_api_key" {
  name        = "brevo-api-key"
  description = "API key for Brevo integration"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "brevo_api_key" {
  secret_id     = aws_secretsmanager_secret.brevo_api_key.id
  secret_string = var.app_brevo_api_key
}

resource "aws_secretsmanager_secret" "turnstile_site_key" {
  name        = "turnstile-site-key"
  description = "Site key for Turnstile integration"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "turnstile_site_key" {
  secret_id     = aws_secretsmanager_secret.turnstile_site_key.id
  secret_string = var.app_turnstile_site_key
}

resource "aws_secretsmanager_secret" "turnstile_secret_key" {
  name        = "turnstile-secret-key"
  description = "Secret key for Turnstile integration"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "turnstile_secret_key" {
  secret_id     = aws_secretsmanager_secret.turnstile_secret_key.id
  secret_string = var.app_turnstile_secret_key
}
