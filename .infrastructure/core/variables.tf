# General vars
variable "github_repository" {
  description = "The Github repository"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

# Application vars
variable "app_brevo_api_key" {
  description = "Brevo API key, optional, leaving blank will result in the application not sending emails"
  type        = string
  sensitive   = true
}

variable "app_turnstile_site_key" {
  description = <<EOT
    Turnstile site key, optional, leaving blank will result in turnstile not being enabled, but will mean no forms can be submitted,
    considering using a test key see https://developers.cloudflare.com/turnstile/troubleshooting/testing/
    EOT
  type        = string
  sensitive   = true
}

variable "app_turnstile_secret_key" {
  description = <<EOT
    Turnstile site key, optional, leaving blank will result in turnstile not being enabled, but will mean no forms can be submitted,
    considering using a test key see https://developers.cloudflare.com/turnstile/troubleshooting/testing/
    EOT
  type        = string
  sensitive   = true
}
