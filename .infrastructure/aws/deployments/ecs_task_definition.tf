resource "aws_ecs_task_definition" "app" {
  family                   = "${aws_ecs_cluster.this.name}-template"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_app.arn

  container_definitions = jsonencode([
    {
      essential = true
      image     = "TO_BE_REPLACED"
      name      = local.ecs_container_name

      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ADMIN_EMAIL",
          value = var.app_admin_email
        },
        {
          name  = "PHX_HOST",
          value = var.app_domain
        }
      ]

      secrets = [
        {
          name      = "SECRET_KEY_BASE"
          valueFrom = aws_secretsmanager_secret_version.secret_key_base.arn
        },
        {
          name      = "DATABASE_CREDENTIALS"
          valueFrom = aws_secretsmanager_secret_version.db_credentials.arn
        },
        {
          name      = "BREVO_API_KEY"
          valueFrom = data.terraform_remote_state.core.outputs.brevo_api_key_arn
        },
        {
          name      = "TURNSTILE_SITE_KEY"
          valueFrom = data.terraform_remote_state.core.outputs.turnstile_site_key_arn
        },
        {
          name      = "TURNSTILE_SECRET_KEY"
          valueFrom = data.terraform_remote_state.core.outputs.turnstile_secret_key_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "stdout"
        }
      }
    }
  ])
}
