output "website_url" {
  description = "Primary site URL once DNS resolves."
  value       = "https://${var.domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (works before DNS cutover for smoke tests)."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  description = "Distribution ID (use for manual invalidations)."
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket" {
  description = "Origin bucket name."
  value       = aws_s3_bucket.site.id
}

output "acm_certificate_arn" {
  value       = aws_acm_certificate_validation.site.certificate_arn
  description = "Validated ACM certificate ARN (us-east-1)."
}

output "route53_name_servers" {
  description = <<-EOT
    Name servers for the Terraform-managed hosted zone. When create_hosted_zone = true,
    set these as the NS records for aish.sh at the domain registrar to complete delegation
    (required before the ACM certificate can validate). Empty when using an existing zone.
  EOT
  value       = var.create_hosted_zone ? aws_route53_zone.this[0].name_servers : []
}

output "hosted_zone_id" {
  description = "Hosted zone ID in use (created or supplied)."
  value       = local.zone_id
}
