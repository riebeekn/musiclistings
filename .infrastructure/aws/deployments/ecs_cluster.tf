locals {
  ecs_container_name = local.name
}

# Create the ECS cluster
resource "aws_ecs_cluster" "this" {
  name = local.name
}
