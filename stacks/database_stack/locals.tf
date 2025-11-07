locals {
  common_tags = {
    Project     = "study-terraform"
    Environment = "dev"
    ManagedBy   = "terraform"
    Phase       = "phase3"
  }
  name_prefix = "${var.project_name}-${var.environment}"
}