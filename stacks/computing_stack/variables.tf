variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "auto scaling group minimum size"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "auto scaling group maximun size"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "auto scaling group desired capacity"
  type        = number
  default     = 2
}
