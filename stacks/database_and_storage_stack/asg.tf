resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-lt-"
  description   = "Launch template for web server instances"
  instance_type = var.web_instance.instance_type
  image_id      = data.aws_ssm_parameter.al2023.value

  metadata_options {
    http_tokens = "required"
  }
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.web.arn
  }
  network_interfaces {
    security_groups = [aws_security_group.web.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web-instance"
    }
  }
  user_data = filebase64("${path.module}/scripts/user_data_web.sh")
}

resource "aws_autoscaling_group" "web" {
  name_prefix               = "${var.project_name}-web-asg-"
  max_size                  = 6
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 120
  health_check_type         = "ELB"
  vpc_zone_identifier       = [for s in aws_subnet.private : s.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  traffic_source {
    identifier = aws_lb_target_group.web.arn
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 90
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-instance"
    propagate_at_launch = true
  }

  # labmda, SNS ...etc (next action...)
  # initial_lifecycle_hook {}

}
