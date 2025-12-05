resource "aws_lb" "web" {
  name = "${var.project_name}-alb"
  # not use bastion, make it internal
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]

  access_logs {
    bucket  = aws_s3_bucket.web.bucket
    enabled = true
    prefix  = "alb-access-logs"
  }
  connection_logs {
    bucket  = aws_s3_bucket.web.bucket
    enabled = true
    prefix  = "alb-connection-logs"
  }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name_prefix = "webtg-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  # to check client IP in logs
  # preserve_client_ip = true

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-alb-target-group"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  tags = {
    Name = "${var.project_name}-alb-listener"
  }
}
