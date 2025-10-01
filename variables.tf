variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "app_count" {
  type    = number
  default = 1
}

variable "ecs_log_driver_options" {
  description = "Options for the AWS Logs driver in ECS task"
  type        = map(string)
  default = {
    "awslogs-region"        = "us-east-1"
    "awslogs-group"         = "web-app"
    "awslogs-stream-prefix" = "ecs"
  }
}

variable "ecs_log_group_name" {
  description = "Name of the CloudWatch Logs group for ECS"
  type        = string
  default     = "web-app"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}