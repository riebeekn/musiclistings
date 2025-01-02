# Create the ECS service
resource "aws_ecs_service" "app" {
  name            = local.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"
  # Note: required for remote access via aws ecs execute-command
  enable_execute_command = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app["blue"].arn
    container_name   = local.ecs_container_name
    container_port   = 4000
  }

  network_configuration {
    security_groups  = [aws_security_group.app.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [
      task_definition, # Managed by GitHub CD pipeline
      load_balancer    # Managed by CodeDeploy for Blue Green deployments
    ]
  }
}
