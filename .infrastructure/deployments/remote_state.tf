# remote_state.tf
# Reference to the core remote state

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "terraform-musiclistings-state"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}
