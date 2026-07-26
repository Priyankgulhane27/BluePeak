# Deployment Instructions

These steps reproduce the entire stack in a fresh AWS account.

## Prerequisites

- AWS CLI v2, authenticated (`aws sts get-caller-identity` works)
- Terraform >= 1.7.0
- Docker (to build the app image)
- An AWS account with permissions to create VPC, ECS, RDS, IAM, S3,
  DynamoDB, CloudWatch, WAF, and Secrets Manager resources

## Step 1 — Bootstrap the Terraform remote state backend

This creates the S3 bucket (versioned, encrypted, private) and DynamoDB lock
table that the main stack's state will live in. Run this once per AWS account.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="state_bucket_name=bluepeak-tf-state-<your-unique-suffix>"
```

Note the `state_bucket` and `lock_table` outputs — you'll need them next.

## Step 2 — Build and push the application image

```bash
cd scripts
./build_and_push.sh us-east-1 bluepeak-counter
```

This creates an ECR repo (with image scanning on push), builds the Docker
image from `app/`, and pushes it. It prints the full image URI at the end —
copy it.

## Step 3 — Configure the environment

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- `container_image` — the ECR URI printed in Step 2
- `alert_email` — where you want CloudWatch alarm emails (optional)
- `certificate_arn` — leave `null` for HTTP-only demo access, or set to a
  validated ACM certificate ARN for HTTPS
- `single_nat_gateway` — `true` for a cheaper dev run, `false` for HA egress

Also update `backend.tf` in this folder (or pass `-backend-config` flags at
init time, shown below) with the bucket/table names from Step 1.

## Step 4 — Initialize and deploy

```bash
terraform init \
  -backend-config="bucket=<state_bucket from step 1>" \
  -backend-config="dynamodb_table=<lock_table from step 1>"

terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Or use the wrapper script from the repo root:

```bash
./scripts/deploy.sh <state-bucket-name> <lock-table-name> apply
```

Apply takes roughly 12-18 minutes, most of it waiting on the Aurora cluster
and instances to become available.

## Step 5 — Verify

```bash
terraform output app_url
```

Open the printed URL in a browser — you should see the Increment/Decrement
counter, and refreshing should show the persisted value (confirming the app
tier successfully wrote to and read from Aurora).

Check the CloudWatch dashboard link from `terraform output cloudwatch_dashboard`.

## Step 6 — Tear down (to avoid ongoing cost)

```bash
terraform destroy -var-file=terraform.tfvars
```

Note: if `environment = "prod"`, `deletion_protection` is enabled on both the
ALB and the Aurora cluster and must be disabled first (change the variable
and re-apply, or use the AWS Console) before `destroy` will succeed. This is
intentional — it's a guardrail, not a bug.

## Reproducing in a different AWS account

Nothing in this repo is account-specific except:
1. The state bucket name (must be globally unique — pick a new one)
2. The `container_image` ECR URI (each account has its own ECR registry)
3. Optional: `certificate_arn` if you want HTTPS with your own domain

Everything else (CIDR ranges, naming, scaling thresholds) is parameterized
via `variables.tf` and safe to reuse as-is or override in `terraform.tfvars`.

## Mapping this into CI/CD (not implemented here, but straightforward)

A GitHub Actions workflow would typically:
1. On push to `main` affecting `app/**` → run `build_and_push.sh` equivalent
   steps, tag the image with the git SHA (not `latest`), push to ECR.
2. Update `container_image` in `terraform.tfvars` (or pass `-var` directly)
   to the new SHA-tagged image.
3. On push to `main` affecting `terraform/**` → `terraform plan` on PR,
   `terraform apply` on merge, using OIDC federation to assume an AWS role
   (no long-lived AWS keys in GitHub Secrets).
