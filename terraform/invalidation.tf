# ---------------------------------------------------------------------------
# Invalidate CloudFront after the uploaded objects change. Requires the AWS CLI
# on the apply host (the same one running `terraform apply`).
# ---------------------------------------------------------------------------
resource "null_resource" "invalidate" {
  count = var.create_invalidation ? 1 : 0

  triggers = {
    # Re-run whenever any uploaded object's content changes.
    content_hash = sha1(join(",", [for o in aws_s3_object.site : o.etag]))
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.site.id} --paths '/*' --profile ${var.aws_profile}"
  }
}
