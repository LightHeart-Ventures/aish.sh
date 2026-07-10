terraform {
  # >= 1.10 for native S3-backend state locking (use_lockfile, no DynamoDB table).
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state in S3 so local runs and CI (.github/workflows/deploy-site.yml)
  # share one authoritative state. `use_lockfile` uses an S3 conditional-write
  # lock (Terraform >= 1.10) — no DynamoDB lock table required.
  #
  # One-time bootstrap + migration of existing local state is documented in
  # README.md § "CI/CD". The state bucket must exist before `terraform init`.
  backend "s3" {
    bucket       = "hohertz-tfstate"
    key          = "aish.sh/site/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
