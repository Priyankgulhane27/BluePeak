# Deployment Instructions

These steps reproduce the entire stack in a fresh AWS account.

## Prerequisites

- AWS CLI v2, authenticated (`aws sts get-caller-identity` works)
- Terraform >= 1.7.0
- Docker (to build the app image)
- An AWS account with permissions to create VPC, ECS, RDS, IAM, S3,
  DynamoDB, CloudWatch, WAF, and Secrets Manager resources

## Step 1 — Create the Terraform remote state backend

This creates the S3 bucket (versioned, encrypted, private) and DynamoDB lock
table that the main stack's state will live in. Run this once per AWS account.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="state_bucket_name=bluepeak-tf-state-<your-unique-suffix>"
```

Note the `state_bucket` and `lock_table` outputs — we will need this details in further implementation.

## Step 2 — Build and push the application image

```bash
cd scripts
./build_and_push.sh us-east-1 bluepeak-counter v1
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
- `container_image` — the ECR URI ehich we received in step 2
- `alert_email` — where you want CloudWatch alarm emails (optional)
- `certificate_arn` — leave `null` for HTTP-only demo access, or set to a
  validated ACM certificate ARN for HTTPS
- `single_nat_gateway` — `true` for demo purpose and low cost , we can set it as `false` for HA egress for production based setup.

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

Or use the wrapper script from the repo root: Better to use this to avoid manual mistakes.

```bash
./scripts/deploy.sh <state-bucket-name> <lock-table-name> apply
```

Apply takes somewhere around 15 to 20 minutes.

## Step 5 — Verify

```bash
terraform output app_url
```

Open the printed URL in a browser — you should see the Increment/Decrement
counter, and clicking on increment or decrement icon should show the count (confirming the app
tier successfully updated and read from DB).

Check the CloudWatch dashboard link from `terraform output cloudwatch_dashboard`.

## Step 6 — Tear down (to avoid ongoing cost)

```bash
terraform destroy -var-file=terraform.tfvars
```
Or use below script.

```bash
./scripts/deploy.sh <state-bucket-name> <lock-table-name> destroy
```
Above command will remove all the rerrafomr resources created which are responsible realted to app configurations.

But it will not delete the reources which we created under bootstrap, the s3 bucket and and DynamoDB lock table.
to remove them run the below commands.
 ```bash
 cd ../../bootstrap
terraform destroy -var="state_bucket_name=bluepeak-tf-state-<your-unique-suffix>"
aws ecr delete-repository --repository-name <REPO_NAME> --region <REGION> --force
```

## Reproducing in a different AWS account

1. The state bucket name (must be globally unique — pick a new one)
2. The `container_image` ECR URI (each account has its own ECR registry)
3. Optional: `certificate_arn` if you want HTTPS with your own domain

Everything else (CIDR ranges, naming, scaling thresholds) is parameterized
via `variables.tf` and safe to reuse as it is or override in `terraform.tfvars`.
