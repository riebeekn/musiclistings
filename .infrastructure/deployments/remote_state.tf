# remote_state.tf
# Reference to the core remote state

data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "../core/terraform.tfstate"
  }
}
