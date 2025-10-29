# ==========================================
# Application Load Balancer
# ==========================================
resource "aws_lb" "main" {
  name               = "study-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = false

  tags = merge(
    {
      Name = "study-alb"
    },
    local.common_tags
  )
}

# ==========================================
# ALB Target Group
# ==========================================
# ALBが転送する先のEC2インスタンスグループ
resource "aws_lb_target_group" "main" {
  name     = "study-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health Check
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
    port                = "traffic-port"
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  # インスタンス削除時の待機時間
  deregistration_delay = 30

  tags = merge(
    {
      Name = "study-alb-tg"
    },
    local.common_tags
  )
}

# ==========================================
# ALB Listener
# ==========================================
# ALBで受け付けたリクエストをTarget Groupに転送
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

}