output "aws_ecr_repository_name" {
  value = aws_ecr_repository.this.name
}

output "aws_iam_openid_connect_provider_for_gh_actions" {
  value       = aws_iam_openid_connect_provider.github_actions.arn
  description = "AWS IAM OpenID Connect Provider ARN for GitHub Actions"
}

output "brevo_api_key_arn" {
  value       = aws_secretsmanager_secret_version.brevo_api_key.arn
  description = "Brevo API Key AWS Secrets Manager ARN"
}

output "turnstile_site_key_arn" {
  value       = aws_secretsmanager_secret_version.turnstile_site_key.arn
  description = "Turnstile site key AWS Secrets Manager ARN"
}

output "turnstile_secret_key_arn" {
  value       = aws_secretsmanager_secret_version.turnstile_secret_key.arn
  description = "Turnstile secret key AWS Secrets Manager ARN"
}
