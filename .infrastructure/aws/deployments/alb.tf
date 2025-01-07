# Create a security group for the load balancer
resource "aws_security_group" "lb" {
  name        = "${local.name}-load-balancer"
  description = "Controls access to the load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Application load balancer
resource "aws_lb" "this" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = module.vpc.public_subnets
}

# Target group for the load balancer
resource "aws_lb_target_group" "app" {
  for_each    = toset(["blue", "green"])
  name        = "${local.name}-${each.key}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/health_check"
    matcher = "200"
  }
}

# Associate the load balancer with the target group via a listener
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["blue"].arn
  }

  lifecycle {
    ignore_changes = [
      default_action # This will be controlled by CodeDeploy
    ]
  }
}
