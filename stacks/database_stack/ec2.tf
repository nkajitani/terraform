resource "aws_instance" "bastion" {
  for_each = aws_subnet.public

  ami                         = data.aws_ssm_parameter.amzn2023_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = each.value.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name

  tags = {
    Name = "${var.project_name}-bastion"
  }
}