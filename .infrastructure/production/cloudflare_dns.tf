resource "cloudflare_record" "www" {
  content = var.cf_www_content
  name    = "www"
  proxied = true
  ttl     = 1
  type    = "A"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "acme_challenge" {
  content = var.cf_acme_challenge_content
  name    = "_acme-challenge"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "root_cname" {
  content = var.cf_root_domain_content
  name    = "torontomusiclistings.com"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "dmarc" {
  content = var.cf_dmarc_content
  name    = "_dmarc"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "dkim" {
  content = var.cf_dkim_content
  name    = "mail._domainkey"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "spf" {
  content = var.cf_spf_content
  name    = "torontomusiclistings.com"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_record" "brevo_txt_record" {
  content = var.cf_brevo_txt_record_content
  name    = "torontomusiclistings.com"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  zone_id = var.cloudflare_zone_id
  lifecycle {
    prevent_destroy = true
  }
}
