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

variable "web_instance" {
  description = "Configuration for the web instance"
  type = object({
    instance_type = string
  })
  default = {
    instance_type = "t3.micro"
  }
}

variable "aurora_username" {
  description = "The master username for the Aurora database"
  type        = string
  default     = "admin"
}

variable "aurora_password" {
  description = "The master password for the Aurora database"
  type        = string
  sensitive   = true
  default     = "password"
}

variable "aurora_version" {
  description = "The version of Aurora MySQL to use"
  type        = string
  default     = "8.0.mysql_aurora.3.10.1"
}

variable "aurora_engine" {
  description = "The database engine for Aurora"
  type        = string
  default     = "aurora-mysql"
}

variable "aurora_instance_class" {
  description = "The instance class for Aurora instances"
  type        = string
  default     = "db.t3.medium"
}
