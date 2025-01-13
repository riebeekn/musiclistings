terraform {
  backend "s3" {
    bucket = "terraform-render-musiclistings-state"
    key    = "deployments/terraform.tfstate"
    region = "us-east-1"
  }
}
