# BluePeak Technologies — AWS Cloud-Native Migration (Assessment Submission)

A private, 3-tier, highly available, auto-scaling AWS architecture,
provisioned entirely with Terraform, hosting an Increment/Decrement counter
app whose count is persisted in a managed RDS PostgreSQL database.

## Repository layout

```
.
├── app/                      # 3-tier counter app (Express + static frontend)
│   ├── server.js             # Application tier: serves frontend, exposes /api/*, talks to RDS
│   ├── public/                # Presentation tier: HTML/CSS/JS counter UI
│   └── Dockerfile
├── terraform/
│   ├── bootstrap/             # One-time: S3 state bucket + DynamoDB lock table
│   ├── environments/dev/      # Root module wiring all sub-modules together
│   └── modules/
│       ├── network/           # VPC, 3-tier subnets, NAT, routing, flow logs
│       ├── security/           # Security group chain (internet -> ALB -> app -> db)
│       ├── alb/                 # Internet-facing ALB, target group, listeners
│       ├── ecs/                 # Fargate cluster/service/task + Application Auto Scaling
│       ├── rds/                 # RDS PostgreSQL, Secrets Manager
│       ├── waf/                 # AWS managed WAF rules on the ALB
│       └── monitoring/          # SNS + CloudWatch alarms/dashboard
├── scripts/
│   ├── build_and_push.sh      # Build & push the app image to ECR
│   └── deploy.sh                # terraform init/plan/apply wrapper
└── docs/
    ├── ARCHITECTURE.md         # Design decisions & rationale
    ├── SECURITY.md              # Security controls, layer by layer
    ├── MONITORING.md            # Alarms + recommended business/ops metrics
    ├── DEPLOYMENT.md            # Step-by-step reproduction instructions
    ├── diagram.drawio           # Editable architecture diagram (draw.io)
    └── diagram.md                # Renders inline on GitHub (Mermaid)
```

## Quick start

Full details in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md). Short version:

```bash
# 1. One-time backend bootstrap
cd terraform/bootstrap && terraform init && terraform apply -var="state_bucket_name=<unique-name>"

# 2. Build & push the app image
cd ../../scripts && ./build_and_push.sh us-east-1 bluepeak-counter

# 3. Configure and deploy
cd ../terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # edit: container_image, alert_email
terraform init -backend-config="bucket=<name>" -backend-config="dynamodb_table=<name>"
terraform apply -var-file=terraform.tfvars

# 4. Visit the app
terraform output app_url
```

## Architecture at a glance

Internet → Route 53 → WAF → ALB (public subnets) → ECS Fargate service
(private app subnets, 2 AZs, auto-scales on CPU + request count) → RDS
PostgreSQL (private DB subnets, no internet route at all).

See [`docs/diagram.md`](docs/diagram.md) for the full diagram and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for why each piece was chosen.

## Design highlights

- **Genuinely 3-tier**: the counter app's state is persisted in RDS via a
  small API layer, not just a decorative unused database.
- **Scales automatically with business-hours demand**: ECS Application Auto
  Scaling handles the app tier (CPU + ALB request count); the RDS instance
  autoscales storage as data grows (`max_allocated_storage`), though compute
  is fixed-size while on the AWS Free Plan — see `docs/ARCHITECTURE.md` for
  the trade-off and how to restore full elastic DB scaling off Free Plan.
- **Least-privilege networking**: DB subnets have zero internet route;
  security groups only allow traffic from the tier directly above them.
- **No hardcoded secrets**: DB password is Terraform-generated, lives only in
  Secrets Manager, injected into the container at runtime.
- **Portable**: every account-specific value is a variable; `terraform/bootstrap`
  is a separate root module so a new AWS account is a 3-command setup.

## Assumptions & constraints

- No pre-existing Route 53 hosted zone or ACM certificate was provided, so
  the ALB defaults to plain HTTP (`certificate_arn = null`). The HTTPS
  listener and redirect logic are fully implemented and activate the moment
  a certificate ARN is supplied — no other changes needed.
- The assessment app (an increment/decrement counter) has no real business
  logic to layer onto the database, so the schema is a single-row counter
  table; the point being demonstrated is the 3-tier data flow and persistence
  pattern, not a complex domain model.
- CI/CD pipeline wiring is described in `docs/DEPLOYMENT.md` but not
  implemented as an actual GitHub Actions workflow file, to keep the
  submission focused on the infrastructure itself.
- Environment scope is `dev` only; `docs/ARCHITECTURE.md` explains exactly
  what changes (NAT count, deletion protection, instance counts) when
  promoting to `staging`/`prod`.
