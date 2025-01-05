output "github_actions_variable_setting-AWS_REGION" {
  value       = var.aws_region
  description = "The AWS region - set this as AWS_REGION in the GHA variables"
}

output "github_actions_variable_setting-AWS_ECR_REPO" {
  value       = data.aws_ecr_repository.this.name
  description = "The ECR repo path - set this as AWS_ECR_REPO in the GHA variables"
}

output "github_actions_variable_setting-AWS_BUILD_ROLE" {
  value       = data.aws_iam_role.github_actions_ecr.arn
  description = "The ARN of the role that can be assumed by GHA to push images to ECR - set this as AWS_BUILD_ROLE in the GHA variables"
}

output "github_actions_variable_setting-AWS_SERVICE_NAME_PREFIX" {
  value       = replace(split("/", var.github_repository)[1], "_", "-")
  description = "The prefix for all AWS services - set this as AWS_SERVICE_NAME_PREFIX in the GHA variables"
}

output "github_actions_variable_setting-AWS_ENVIRONMENTS" {
  value       = "include the current environment which is: '${var.environment}'"
  description = <<EOF
    "The current environment - include this as part of the AWS_ENVIRONMENTS GHA variable, i.e. staging...
    if you have multiple environments use a comma separated list, such as staging, qa"
  EOF
}

output "github_actions_variable_setting-AWS_ACCOUNT_ID" {
  value       = var.aws_account_id
  description = "The AWS account id - set this as AWS_ACCOUNT_ID in the GHA variables"
}

output "db_instance_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "db_instance_name" {
  value = aws_db_instance.db.db_name
}

output "db_instance_user" {
  value       = aws_db_instance.db.username
  description = "Database username"
}

output "db_instance_password" {
  value       = aws_db_instance.db.password
  description = "Database password"
  sensitive   = true
}
