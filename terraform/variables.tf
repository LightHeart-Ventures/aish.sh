variable "aws_region" {
  description = "AWS region for the S3 origin bucket (CloudFront is global; ACM is pinned to us-east-1 separately)."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Named AWS profile used to deploy. The site account is hohertz (691716211469)."
  type        = string
  default     = "hohertz"
}

variable "domain_name" {
  description = "Apex domain for the marketing site."
  type        = string
  default     = "aish.sh"
}

variable "create_www" {
  description = "Also serve and certify www.<domain_name> (redirected to apex at the DNS/alias level)."
  type        = bool
  default     = true
}

variable "create_hosted_zone" {
  description = <<-EOT
    When true, Terraform creates and manages the Route53 hosted zone for domain_name
    in THIS account, and you must point the registrar's NS records at the emitted
    name_servers output. When false, supply an existing hosted_zone_id (its account must
    be the same one Terraform is authenticated against).
  EOT
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "Existing Route53 hosted zone ID for domain_name. Required only when create_hosted_zone = false."
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Override the S3 origin bucket name. Defaults to aish-site-<account_id> when empty."
  type        = string
  default     = ""
}

variable "site_dir" {
  description = "Path to the built static site to upload."
  type        = string
  default     = "../site"
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = NA + EU (cheapest)."
  type        = string
  default     = "PriceClass_100"
}

variable "create_invalidation" {
  description = "Create a CloudFront invalidation (/*) after object uploads change. Requires the AWS CLI on the apply host."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    Project   = "aish"
    Component = "marketing-site"
    ManagedBy = "terraform"
    Repo      = "LightHeart-Ventures/aish.sh"
  }
}
