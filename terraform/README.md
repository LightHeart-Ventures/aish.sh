# Deploying the aish.sh marketing site (S3 + CloudFront + ACM + Route53)

Terraform for the static marketing site in [`../site`](../site). Private S3 origin,
CloudFront with Origin Access Control (OAC), an ACM TLS certificate in `us-east-1`,
and Route53 DNS — all in the **hohertz** AWS account (`691716211469`).

```
terraform/
├── versions.tf       provider + version pins (local state by default)
├── providers.tf      aws (var.aws_region) + aws.us_east_1 (for ACM)
├── variables.tf      all inputs
├── terraform.tfvars  values for aish.sh
├── main.tf           locals: aliases, bucket name, zone id, mime map, file set
├── s3.tf             private bucket, OAC-scoped policy, per-file uploads
├── acm.tf            DNS-validated certificate (apex + www)
├── cloudfront.tf     distribution, managed cache + security-headers policies
├── dns.tf            hosted zone (optional) + apex/www A + AAAA aliases
├── invalidation.tf   CloudFront /* invalidation on content change
└── outputs.tf        URL, distribution id, bucket, name servers, cert ARN
```

## Prerequisites

- Terraform >= 1.6, AWS CLI configured with the `hohertz` profile.
- The static site already built in `../site` (it is — plain HTML/CSS/JS, zero build step).

## One-time DNS note (read this first)

`aish.sh` is **not** a Route53 hosted zone in the hohertz account today — its live
name servers point at a zone in a different AWS account. This module therefore
defaults to `create_hosted_zone = true`, creating a fresh hosted zone here. The
ACM certificate uses DNS validation, so it cannot issue until `aish.sh`'s registrar
NS records point at this new zone.

Two supported paths:

1. **Create the zone here (default).** Run the apply; it will create everything and
   then wait on certificate validation. Take the `route53_name_servers` output and set
   them as the NS for `aish.sh` at the registrar. Once delegation propagates (minutes
   to an hour), validation completes. To avoid a long wait inside a single apply, you
   can stage it:

   ```bash
   export AWS_PROFILE=hohertz
   terraform init
   terraform apply -target=aws_route53_zone.this        # create zone, get NS
   terraform output route53_name_servers                # set these at the registrar
   # ...after NS delegation propagates:
   terraform apply                                       # finish cert + CloudFront
   ```

2. **Use the existing zone's account.** Authenticate Terraform against the account that
   already owns the `aish.sh` zone and set in `terraform.tfvars`:

   ```hcl
   create_hosted_zone = false
   hosted_zone_id     = "<existing-zone-id>"
   ```

## Deploy

```bash
export AWS_PROFILE=hohertz
terraform init
terraform plan
terraform apply
```

Outputs include the live `cloudfront_domain_name`, which serves the site over HTTPS
immediately (on the `*.cloudfront.net` name) for smoke-testing before DNS cutover.

## Updating the site

Re-running `terraform apply` re-uploads any changed files (content-addressed via
`filemd5`) and issues a CloudFront `/*` invalidation automatically.

## Cost

Tiny: S3 storage of a ~50 KB site, CloudFront `PriceClass_100`, one ACM cert (free),
one hosted zone ($0.50/mo). Effectively a few cents/month plus request volume.
