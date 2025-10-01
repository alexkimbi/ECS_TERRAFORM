resource "aws_lb" "lb" {
  name            = "web-lb"
  subnets         = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id, aws_subnet.public_subnet[2].id]
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "web-tg" {
  name        = "web-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web-tg.id
    type             = "forward"
  }
}

output "tg_arn" {
  description = "Load balancer DNS arn"
  value       = aws_lb_target_group.web-tg.arn

}

output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = aws_lb.lb.dns_name

}

