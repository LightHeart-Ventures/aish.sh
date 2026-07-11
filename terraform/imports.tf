# ---------------------------------------------------------------------------
# Terraform >= 1.5 import blocks: declare existing AWS resources
# instead of trying to create them. These resources were previously
# imported via `terraform import` commands in PR #14 and stored in remote state.
#
# Migration from `terraform import` CLI to declarative import blocks:
# - Cleaner audit trail (resources declared in code, not hidden in CLI history)
# - Import blocks are executed during `terraform plan` (no separate step)
# - State is synchronized on each run
# ---------------------------------------------------------------------------

import {
  to = aws_s3_bucket.site
  id = "hohertz-aish-site-691716211469"
}

import {
  to = aws_cloudfront_origin_access_control.site
  id = "E2GZUHBIFMQC0X"
}
