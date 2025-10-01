resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "web-td" {
  family                   = "web-app"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([{
    name         = "web-app",
    image        = local.terraform.image,
    essential    = true,
    portMappings = [{ containerPort = 3000, hostPort = 3000 }],

    environment = [
      { name = "APPENV", value = "Test" }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = merge(var.ecs_log_driver_options, {
        "awslogs-group" = aws_cloudwatch_log_group.log_group.name,
      })
    },
  }])
}