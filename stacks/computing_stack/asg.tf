# ==========================================
# Launch Template
# ==========================================
# ASGが起動するEC2の設定テンプレート
resource "aws_launch_template" "main" {
  name_prefix   = "study-templete-"
  image_id      = data.aws_ssm_parameter.amzn2023_ami.value
  instance_type = var.instance_type

  # Web Server用のSecurity Group
  vpc_security_group_ids = [aws_security_group.web.id]

  # script to configure EC2 instance at launch
  user_data = base64encode(file("${path.module}/user_data.sh"))

  metadata_options {
    http_tokens                 = "required" # Instance Metadata Service v2 (IMDSv2)を強制
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        Name = "study-asg-instance"
      }
    )
  }
}

# ==========================================
# Auto Scaling Group
# ==========================================
resource "aws_autoscaling_group" "main" {
  name = "study-asg"

  # Private Subnetに配置（Multi-AZ）
  vpc_zone_identifier = [for s in aws_subnet.private : s.id]

  # ALBのTarget Groupに登録
  target_group_arns = [aws_lb_target_group.main.arn]

  # スケーリング設定
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Health Check設定
  health_check_grace_period = 300
  health_check_type         = "ELB"

  # Launch Templateの指定
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # インスタンス更新ポリシー（Rolling Update）
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "study-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = local.common_tags["Project"]
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = local.common_tags["Environment"]
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = local.common_tags["ManagedBy"]
    propagate_at_launch = true
  }
}

# ==========================================
# Auto Scaling Policy
# ==========================================
resource "aws_autoscaling_policy" "cpu_scale_up" {
  name                   = "study-asg-cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}