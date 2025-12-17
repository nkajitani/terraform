terraform {
  required_version = "~> 1.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
provider "aws" {
  region = var.region
}
provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}
