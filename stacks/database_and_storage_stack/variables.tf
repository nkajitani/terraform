variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "The name of the project for tagging resources"
  type        = string
  default     = "database-and-storage"
}

variable "subnets" {
  description = "A map of subnet configurations"
  type = object({
    public  = map(object({ cidr = string, az = string }))
    private = map(object({ cidr = string, az = string }))
  })
  default = {
    public = {
      "a" = { cidr = "10.0.1.0/24", az = "ap-northeast-1a" }
      "c" = { cidr = "10.0.2.0/24", az = "ap-northeast-1c" }
    }
    private = {
      "a" = { cidr = "10.0.3.0/24", az = "ap-northeast-1a" }
      "c" = { cidr = "10.0.4.0/24", az = "ap-northeast-1c" }
    }
  }
}
