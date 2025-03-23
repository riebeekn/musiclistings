# For IP allow list
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "render_postgres" "this" {
  name = "${local.name}-database"
  plan = var.render_postgres_plan
  # can't select disk size for free plan
  disk_size_gb  = var.render_postgres_plan == "free" ? null : var.render_postgres_disk_size
  region        = var.render_region
  version       = "15"
  database_name = replace(local.name, "-", "_")

  ip_allow_list = [
    {
      # cidr_block  = "0.0.0.0/0",
      # description = "Allow all traffic"
      cidr_block  = "${chomp(data.http.myip.response_body)}/32"
      description = "Allow my IP"
    }
  ]
}
