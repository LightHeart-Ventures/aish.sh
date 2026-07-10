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

- Terraform >= 1.10 (native S3-backend state locking), AWS CLI configured with the `hohertz` profile.
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

## Remote state

State lives in S3 (`s3://hohertz-tfstate/aish.sh/site/terraform.tfstate`, see
`versions.tf`) so local runs and CI share one authoritative state. Locking uses
the native S3 conditional-write lockfile (`use_lockfile`, Terraform >= 1.10) — no
DynamoDB table needed.

**One-time bootstrap** (the state bucket must exist before `init`):

```bash
export AWS_PROFILE=hohertz
aws s3api create-bucket --bucket hohertz-tfstate --region us-east-1
aws s3api put-bucket-versioning --bucket hohertz-tfstate \
  --versioning-configuration Status=Enabled
```

**Migrating existing local state** into the bucket (run once, from `terraform/`):

```bash
export AWS_PROFILE=hohertz
terraform init -migrate-state   # answers "yes" to copy local -> S3
```

After migration, `git`-ignored `*.tfstate` files can be deleted locally.

## CI/CD (GitHub Actions)

`.github/workflows/deploy-site.yml` deploys automatically:

| Trigger | Action |
| --- | --- |
| `pull_request` (touching `site/**` or `terraform/**`) | `fmt` + `validate` + `plan` only |
| `push` to `main` | `plan` + `apply` + CloudFront invalidation |
| `workflow_dispatch` | manual `plan` + `apply` |

Auth is via **GitHub OIDC** (no long-lived keys). CI blanks `aws_profile`
with a command-line `-var=aws_profile=` (via `TF_CLI_ARGS_plan`/`TF_CLI_ARGS_apply`)
so the provider and AWS CLI use the assumed-role credential chain. A plain
`TF_VAR_aws_profile` would not work — `terraform.tfvars` (`aws_profile = "hohertz"`)
overrides environment variables in Terraform's precedence order.

**One-time setup:**

1. **Migrate state to S3.** The backend (`terraform/versions.tf`) is an S3
   bucket so local runs and CI share one authoritative state. Create the bucket
   once and migrate the existing local state into it — do this from a laptop
   that still has the local `terraform.tfstate`, BEFORE the first CI run:

   ```sh
   aws s3api create-bucket --bucket hohertz-tfstate --region us-east-1 --profile hohertz
   aws s3api put-bucket-versioning --bucket hohertz-tfstate \
     --versioning-configuration Status=Enabled --profile hohertz
   cd terraform && terraform init -migrate-state   # answer "yes" to copy state
   ```

   Skipping this makes CI start from an empty state and attempt to re-create
   already-deployed resources. `use_lockfile` (Terraform >= 1.10) provides the
   state lock via an S3 conditional write — no DynamoDB table needed.

2. Create an IAM role in the `hohertz` account (`691716211469`) that trusts this
   repo's OIDC subject. Add the GitHub OIDC provider
   (`token.actions.githubusercontent.com`) if the account doesn't have one, then
   attach a trust policy like:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": { "Federated": "arn:aws:iam::691716211469:oidc-provider/token.actions.githubusercontent.com" },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
         "StringLike":   { "token.actions.githubusercontent.com:sub": "repo:LightHeart-Ventures/aish.sh:*" }
       }
     }]
   }
   ```

   Grant the role the same permissions the `terraform` IAM user has today
   (S3 on `hohertz-*` incl. `hohertz-tfstate`, CloudFront, ACM, Route53).

3. Add the role ARN as a repo secret named **`AWS_DEPLOY_ROLE_ARN`**
   (`gh secret set AWS_DEPLOY_ROLE_ARN`).

4. (Optional) Create a **`production`** environment in repo settings to require a
   manual approval before `apply`.

## Cost

Tiny: S3 storage of a ~50 KB site, CloudFront `PriceClass_100`, one ACM cert (free),
one hosted zone ($0.50/mo). Effectively a few cents/month plus request volume.
