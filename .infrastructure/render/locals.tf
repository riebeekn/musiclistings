locals {
  name = "${replace(split("/", var.github_repository)[1], "_", "-")}-${var.environment}"
}
