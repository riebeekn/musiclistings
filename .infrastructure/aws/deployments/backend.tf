terraform {
  backend "s3" {
    bucket = "terraform-musiclistings-state"
    key    = "deployments/terraform.tfstate"
    region = "us-east-1"
  }
}
