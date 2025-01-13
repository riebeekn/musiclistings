terraform {
  required_providers {
    # AWS is used for Terraform state storage
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    render = {
      source  = "render-oss/render"
      version = "1.3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "render" {
  api_key  = var.render_api_key
  owner_id = var.render_owner_id
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
