# General vars
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

# Production Cloudflare DNS settings
variable "cf_acme_challenge_content" {
  description = "Content value for acme_challenge CNAME record"
  type        = string
}

variable "cf_brevo_txt_record_content" {
  description = "Content value for brevo-code TXT record"
  type        = string
}

variable "cf_dkim_content" {
  description = "Content value for DKIM TXT record"
  type        = string
}

variable "cf_dmarc_content" {
  description = "Content value for DMARC TXT record"
  type        = string
}

variable "cf_root_domain_content" {
  description = "Content value for root domain CNAME record"
  type        = string
}

variable "cf_spf_content" {
  description = "Content value for SPF TXT record"
  type        = string
}

variable "cf_www_content" {
  description = "Content value for www A record"
  type        = string
}
