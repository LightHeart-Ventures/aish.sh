data "aws_caller_identity" "current" {}

locals {
  # Apex + optional www.
  aliases = var.create_www ? [var.domain_name, "www.${var.domain_name}"] : [var.domain_name]
  sans    = var.create_www ? ["www.${var.domain_name}"] : []

  bucket_name = coalesce(var.bucket_name, "aish-site-${data.aws_caller_identity.current.account_id}")

  zone_id = var.create_hosted_zone ? aws_route53_zone.this[0].zone_id : var.hosted_zone_id

  # Static MIME map for the small, known set of site assets.
  mime_types = {
    ".html"  = "text/html; charset=utf-8"
    ".css"   = "text/css; charset=utf-8"
    ".js"    = "application/javascript; charset=utf-8"
    ".json"  = "application/json"
    ".svg"   = "image/svg+xml"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".webp"  = "image/webp"
    ".ico"   = "image/x-icon"
    ".txt"   = "text/plain; charset=utf-8"
    ".xml"   = "application/xml"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".map"   = "application/json"
    ".md"    = "text/markdown; charset=utf-8"
  }

  # Upload everything except docs/source-only files.
  site_files = toset([
    for f in fileset(var.site_dir, "**") : f
    if !endswith(f, ".md")
  ])
}
