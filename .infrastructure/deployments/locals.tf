locals {
  name                   = "${replace(split("/", var.github_repository)[1], "_", "-")}-${var.environment}"
  vpc_availability_zones = var.vpc_availability_zones == null ? formatlist("${var.aws_region}%s", ["a", "b"]) : var.vpc_availability_zones
}
