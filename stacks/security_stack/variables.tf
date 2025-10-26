variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}