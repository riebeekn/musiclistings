resource "cloudflare_turnstile_widget" "turnstile" {
  account_id = var.cloudflare_account_id
  domains    = ["torontomusiclistings.com"]
  mode       = "managed"
  name       = "TMLTurnstileWidget"
  region     = "world"
  lifecycle {
    prevent_destroy = true
  }
}
