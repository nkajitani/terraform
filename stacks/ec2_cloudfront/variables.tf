variable "project_name" {
  type        = string
  description = "project name"
  default     = "ec2-cloudfront-nkajitani"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-northeast-1"
}

variable "public_subnet" {
  type        = object({ cidr = string, az = string })
  description = "Public subnet configuration"
  default     = { cidr = "10.0.1.0/24", az = "ap-northeast-1a" }
}

variable "domain_name" {
  type        = string
  description = "The domain name for the ACM certificate"
  default     = "dev.nkajitani.com"
}
