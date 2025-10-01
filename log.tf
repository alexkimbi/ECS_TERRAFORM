resource "aws_cloudwatch_log_group" "log_group" {
  name = var.ecs_log_group_name

}