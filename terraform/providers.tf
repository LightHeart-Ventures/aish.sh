# Primary provider — S3 bucket lives here.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = var.tags
  }
}

# CloudFront requires its ACM certificate in us-east-1, regardless of where
# the bucket lives. This aliased provider is used only for the certificate.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = var.tags
  }
}
