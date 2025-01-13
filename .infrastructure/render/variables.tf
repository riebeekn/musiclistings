# General vars
variable "aws_region" {
  description = "The AWS region (AWS is used for S3 terraform state bucket)"
  type        = string
  default     = "us-east-1"
}

variable "basic_auth_username" {
  description = <<EOF
    "Username for basic authentication, if this and basic_auth_password
    are set to a non-empty value, basic auth will be enabled... default
    to empty string to avoid accidental enabling of basic auth"
  EOF
  type        = string
  sensitive   = true
  default     = ""
}

variable "basic_auth_password" {
  description = <<EOF
    "Password for basic authentication, if this and basic_auth_username
    are set to a non-empty value, basic auth will be enabled... default
    to empty string to avoid accidental enabling of basic auth"
  EOF
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "The environment to deploy, i.e. qa, staging, prod"
  type        = string
}

variable "github_repository" {
  description = "The Github repository"
  type        = string
}

variable "render_api_key" {
  description = "Render API Key"
  type        = string
  sensitive   = true
}

variable "render_owner_id" {
  description = "Render Owner ID"
  type        = string
  sensitive   = true
}

variable "render_region" {
  description = "The Render region to deploy to"
  type        = string
}

variable "render_postgres_plan" {
  description = "The Render postgres plan"
  type        = string
}

variable "render_web_service_plan" {
  description = "The Render web service plan"
  type        = string
}

# Application vars
variable "app_admin_email" {
  description = "The email for the application administrator"
  type        = string
}

variable "app_brevo_api_key" {
  description = "Brevo API key, optional, leaving blank will result in the application not sending emails"
  type        = string
  sensitive   = true
}

variable "app_domain" {
  description = "The domain for the application"
  type        = string
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
