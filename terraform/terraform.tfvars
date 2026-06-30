# aish.sh marketing site — deployment config.
# Deploy account: hohertz (691716211469). ACM is pinned to us-east-1 in code.

aws_region  = "us-east-1"
aws_profile = "hohertz"
domain_name = "aish.sh"
create_www  = true

# aish.sh is NOT currently a Route53 zone in the hohertz account (its live NS
# point at a zone in a different account). Default below creates a fresh,
# Terraform-managed zone here; after `apply`, set the emitted
# `route53_name_servers` as the NS for aish.sh at the registrar to finish
# delegation (the ACM cert validates only once delegation propagates).
#
# If you instead authenticate Terraform against the account that already owns
# the aish.sh zone, set:
#   create_hosted_zone = false
#   hosted_zone_id     = "<existing-zone-id>"
create_hosted_zone = true

price_class         = "PriceClass_100"
create_invalidation = true
