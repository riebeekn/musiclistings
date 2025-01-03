# CloudWatch log group
resource "aws_cloudwatch_log_group" "group" {
  name = "/ecs/${local.name}"
}

# Allows the application container to pass logs to CloudWatch
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.private_subnets

  tags = {
    Name = "logs-endpoint"
  }
}
