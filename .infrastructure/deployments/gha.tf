# gha.tf
# Contains the Terraform code to create the neccesary resources for executing
# GitHub Actions and deploying images to the ECS repository

locals {
  ecr_name = replace(data.aws_ecr_repository.this.name, "/", "-")
  ecs_name = aws_ecs_cluster.this.name
}

data "aws_iam_role" "github_actions_ecr" {
  name = "github-actions-ecr-${local.ecr_name}"
}

data "aws_iam_openid_connect_provider" "github_actions" {
  arn = data.terraform_remote_state.core.outputs.aws_iam_openid_connect_provider_for_gh_actions
}

data "aws_iam_policy_document" "github_actions_oidc" {
  statement {
    sid     = "GithubActionsRepoAssume"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = ["repo:${var.github_repository}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecs" {
  name               = "github-actions-ecs-${local.ecs_name}"
  description        = "Allow for github actions to deploy to ${local.ecs_name} ECS"
  assume_role_policy = data.aws_iam_policy_document.github_actions_oidc.json
}

resource "aws_iam_role_policy" "github_ecs_role_policy" {
  name   = "${local.ecs_name}-ecs"
  role   = aws_iam_role.github_actions_ecs.id
  policy = data.aws_iam_policy_document.github_actions_ecs.json
}

resource "aws_iam_role_policies_exclusive" "github_ecs_role_policy_exclusive" {
  role_name    = aws_iam_role.github_actions_ecs.name
  policy_names = [aws_iam_role_policy.github_ecs_role_policy.name]
}

data "aws_iam_policy_document" "github_actions_ecs" {
  statement {
    sid    = "RegisterTaskDefinition"
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "PassRolesInTaskDefinition"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_task_app.arn,
      aws_iam_role.ecs_task_execution.arn
    ]
  }
  statement {
    sid    = "DeployService"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      aws_codedeploy_app.this.arn,
      aws_codedeploy_deployment_group.this.arn,
      "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentconfig:*",
      aws_ecs_service.app.id
    ]
  }
}
