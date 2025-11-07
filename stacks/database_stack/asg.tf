resource "aws_launch_template" "web" {
  description = "Launch template for web server instances"

  name_prefix   = "study-web-lt-"
  image_id      = data.aws_ssm_parameter.amzn2023_ami.value
  instance_type = var.web_instance_type
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    aurora_writer_endpoint = aws_rds_cluster.aurora.endpoint
    aurora_reader_endpoint = aws_rds_cluster.aurora.reader_endpoint
    db_name                = var.aurora_name
    db_username            = var.aurora_username
  }))

  metadata_options {
    http_tokens = "required"
  }
  monitoring {
    enabled = true
  }
  network_interfaces {
    security_groups = [aws_security_group.web.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "study-web-instance"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix               = "study-web-asg"
  max_size                  = 6
  min_size                  = 1
  desired_capacity          = 3
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [for s in aws_subnet.private : s.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  traffic_source {
    identifier = aws_lb_target_group.main.arn
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
      skip_matching          = true
      auto_rollback          = true
    }
  }
  tag {
    key                 = "Name"
    value               = "study-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web" {
  name                   = "study-web-asg-cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}