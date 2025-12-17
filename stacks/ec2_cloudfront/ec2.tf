resource "aws_instance" "main" {
  subnet_id                   = aws_subnet.public.id
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  instance_type               = "t3.micro"
  ami                         = data.aws_ssm_parameter.al2023.value
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
  }
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data_base64 = filebase64("${path.module}/scripts/user_data.sh")

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
