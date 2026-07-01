terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Local state by default. To collaborate, switch to an S3 backend, e.g.:
  #
  # backend "s3" {
  #   bucket = "hohertz-tfstate"
  #   key    = "aish.sh/site/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
