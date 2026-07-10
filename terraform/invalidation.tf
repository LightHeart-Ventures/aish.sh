# ---------------------------------------------------------------------------
# Invalidate CloudFront after the uploaded objects change. Requires the AWS CLI
# on the apply host (the same one running `terraform apply`; present on the
# GitHub Actions ubuntu runner and on a dev laptop).
# ---------------------------------------------------------------------------
resource "null_resource" "invalidate" {
  count = var.create_invalidation ? 1 : 0

  triggers = {
    # Re-run whenever any uploaded object's content changes.
    content_hash = sha1(join(",", [for o in aws_s3_object.site : o.etag]))
  }

  provisioner "local-exec" {
    # Only pass --profile when one is set (local dev). In CI aws_profile is blank
    # and the AWS CLI uses the OIDC credential chain from the environment.
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.site.id} --paths '/*'${var.aws_profile != "" ? " --profile ${var.aws_profile}" : ""}"
  }
}
