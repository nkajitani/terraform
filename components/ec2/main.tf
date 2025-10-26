provider "aws" {
  region = "ap-northeast-1"
}

data "aws_ssm_parameter" "ec2" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ssm_parameter.ec2.value
  instance_type = "t2.micro"
  tags = { Name = "study-ec2-al2023-x86" }
}
