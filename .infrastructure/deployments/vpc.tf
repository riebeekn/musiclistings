# vpc.tf
# Contains the Terraform code to create the VPC for the application

# Create the VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = var.vpc_cidr

  azs             = local.vpc_availability_zones
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true
  # Note: nat_gateway required for remote access via aws ecs execute-command
  # and to open a DB tunnel.  They are expensive, so only enable if needed.
  enable_nat_gateway = var.vpc_enable_nat_gateway
}

# Allows the private subnet to communicate with services
resource "aws_security_group" "vpc_endpoint" {
  name        = "${local.name}-vpc-endpoint"
  description = "Controls access to VPC endpoints"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
}
