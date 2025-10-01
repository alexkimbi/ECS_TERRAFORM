resource "aws_ecs_cluster" "main" {
  name = "app-cluster"
  setting {
        name  = "containerInsights"
        value = "enabled"
  }
}

resource "aws_ecs_service" "web_ecs" {
  name            = "web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web-td.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.web_task.id]
    subnets         = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web-tg.id
    container_name   = "web-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.hello_world]
}