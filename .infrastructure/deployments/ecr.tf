data "aws_ecr_repository" "this" {
  name = data.terraform_remote_state.core.outputs.aws_ecr_repository_name
}
