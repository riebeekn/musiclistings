terraform {
  backend "s3" {
    bucket = "terraform-musiclistings-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}
