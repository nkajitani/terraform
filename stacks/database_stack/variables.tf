variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "study-terraform"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A map of public subnets to be created"
  type = map(object({
    cidr = string
    az   = string
  }))

  default = {
    "a" = {
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-1a"
    }
    "b" = {
      cidr = "10.0.3.0/24"
      az   = "ap-northeast-1c"
    }
  }
}

variable "private_subnets" {
  description = "A map of private subnets to be created"
  type = map(object({
    cidr = string
    az   = string
  }))

  default = {
    "a" = {
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-1a"
    }
    "b" = {
      cidr = "10.0.4.0/24"
      az   = "ap-northeast-1c"
    }
  }
}

variable "rds_subnets" {
  description = "A map of RDS subnets to be created"
  type = map(object({
    cidr = string
    az   = string
  }))

  default = {
    "a" = {
      cidr = "10.0.5.0/24"
      az   = "ap-northeast-1a"
    }
    "b" = {
      cidr = "10.0.6.0/24"
      az   = "ap-northeast-1c"
    }
  }
}

variable "web_instance_type" {
  description = "The instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "admin_ips" {
  description = "List of admin IPs allowed to access the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "ssh key name for EC2 instances"
  type        = string
  default     = "my-key"
}

variable "aurora_instance_count" {
  description = "Number of Aurora RDS instances"
  type        = number
  default     = 2
}

variable "aurora_instance_class" {
  description = "Instance class for Aurora RDS instances"
  type        = string
  default     = "db.t3.medium"
}

variable "aurora_name" {
  description = "The name of the default database in Aurora cluster"
  type        = string
  default     = "studydb"
}

variable "aurora_username" {
  description = "The username of the default database in Aurora cluster"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "aurora_password" {
  description = "The password of the default database in Aurora cluster"
  type        = string
  default     = "password"
  sensitive   = true
}
