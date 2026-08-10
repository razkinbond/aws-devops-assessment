variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, staging, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "db_name" {
  type        = string
  description = "PostgreSQL Database Name"
}

variable "db_username" {
  type        = string
  description = "PostgreSQL Master Username"
}

variable "db_instance_class" {
  type        = string
  description = "RDS Instance Type"
}

variable "ecs_desired_count" {
  type        = number
  description = "Number of ECS tasks to run per service"
}

variable "container_cpu" {
  type        = string
  description = "CPU units for ECS tasks (e.g. 256 = 0.25 vCPU)"
}

variable "container_memory" {
  type        = string
  description = "Memory for ECS tasks in MB"
}

variable "alert_enabled" {
  type        = bool
  description = "Create CloudWatch alarms and SNS notifications"
  default     = true
}

variable "alert_email" {
  type        = string
  description = "Email address for CloudWatch alarm notifications"
  default     = ""
}