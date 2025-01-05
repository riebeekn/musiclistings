terraform {
  backend "s3" {
    bucket = "terraform-musiclistings-state"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}
