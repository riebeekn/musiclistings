# ecr.tf
# Contains the Terraform code to create the ECR repository for the application

resource "aws_ecr_repository" "this" {
  name = var.github_repository
  lifecycle {
    prevent_destroy = true
  }
}
