# General vars
variable "github_repository" {
  description = "The Github repository"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "The environment to deploy, i.e. qa, staging, prod"
  type        = string
}

variable "basic_auth_username" {
  description = <<EOF
    "Username for basic authentication, if this and basic_auth_password
    are set to a non-empty value, basic auth will be enabled... default
    to empty string to avoid accidental enabling of basic auth"
  EOF
  type        = string
  sensitive   = true
  default     = ""
}

variable "basic_auth_password" {
  description = <<EOF
    "Password for basic authentication, if this and basic_auth_username
    are set to a non-empty value, basic auth will be enabled... default
    to empty string to avoid accidental enabling of basic auth"
  EOF
  type        = string
  sensitive   = true
  default     = ""
}

# Application vars
variable "app_admin_email" {
  description = "The email for the application administrator"
  type        = string
}

variable "app_domain" {
  description = "The domain for the application"
  type        = string
}

# VPC vars
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR for the VPC"
}

variable "vpc_public_subnets" {
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "Public subnets for the VPC"
}

variable "vpc_private_subnets" {
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "Private subnets for the VPC"
}

variable "vpc_availability_zones" {
  default     = null
  description = "Availability zones for subnets"
}

variable "vpc_enable_nat_gateway" {
  description = <<EOF
      "Whether to enable nat_gateway or not, these are required for
      remote access via aws ecs execute-command and to open a DB tunnel.
      They are expensive, so only enable if needed."
    EOF
}

# RDS vars
variable "rds_db_username" {
  description = "The RDS database username"
  type        = string
}

variable "rds_db_port" {
  description = "The RDS database port"
  type        = number
  default     = null
}

variable "rds_instance_type" {
  description = "RDS instance type"
  type        = string
}

variable "rds_encrypt_at_rest" {
  description = "DB encryption setting"
  type        = bool
  default     = false
}

# ECS vars
variable "ecs_service_desired_count" {
  description = "The number of tasks to run for the ECS service"
  type        = number
}

variable "ecs_task_cpu" {
  description = "The CPU units for the ECS task"
  type        = number
}

variable "ecs_task_memory" {
  description = "The memory for the ECS task"
  type        = number
}

# Code deploy vars
variable "codedeploy_termination_wait_time" {
  description = "Termination wait time on successful deployment in minutes"
  type        = number
  default     = 5
}
