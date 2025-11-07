resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.project_name}-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content              = tls_private_key.bastion.private_key_pem
  filename             = "${path.module}/bastion_key.pem"
  file_permission      = "0400"
  directory_permission = "0700"
}