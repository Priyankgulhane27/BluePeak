# Architecture & Design Decisions — BluePeak Technologies AWS Migration

## 1. Objective

Provide BluePeak, a finance company migrating off on-prem infrastructure, with a
private, 3-tier, internet-facing, highly available, auto-scaling architecture on
AWS, provisioned entirely through Terraform.

See [`diagram.md`](./diagram.md) for a renderable diagram and [`diagram.drawio`](./diagram.drawio)
for the editable version.

## 2. Tier breakdown and mapping to requirements

| Requirement | Design decision |
|---|---|
| Private network, 3-tier design | VPC with public / private-app / private-db subnets across 2 AZs (`az_count` is configurable up to 3) |
| Internet accessible | Internet-facing ALB in public subnets is the only ingress path; WAF sits in front of it |
| High availability & scalability | ECS Fargate service spread across AZs behind the ALB; Aurora Multi-AZ cluster with a dedicated writer + reader |
| Managed DB, HA + scalable | Amazon Aurora MySQL, Serverless v2 engine mode — capacity scales automatically (0.5–4 ACUs by default) and failover is automated |
| Traffic fluctuates during business hours, must autoscale | Application Auto Scaling on the ECS service using two target-tracking policies: average CPU utilization and ALB `RequestCountPerTarget` |
| Recommend operational/business metrics | See [`MONITORING.md`](./MONITORING.md) |

## 3. Why these specific choices

**ECS Fargate over EC2 Auto Scaling Groups.** No OS patching, no AMI pipeline,
faster scale-out (new tasks in ~30-60s vs EC2 boot times), and cost is pay-per-task
rather than pay-per-instance-even-if-idle. For a small counter app this is also
simply cheaper to run continuously than a fleet of EC2 instances sized for peak.
Trade-off: less control over the underlying host, and cold-start latency is
slightly higher than a warm EC2 fleet — acceptable here given the workload profile.

**Aurora Serverless v2 over standard provisioned RDS.** The prompt explicitly
calls out fluctuating business-hours traffic. Serverless v2 scales ACUs up/down
in fine increments within seconds without a failover event, so the database
tier tracks the app tier's scaling instead of being sized for peak 24/7.
Standard provisioned Aurora/RDS was considered but rejected because it requires
either over-provisioning for peak or manual/scheduled resizing.

**Separate private-app and private-db subnet tiers instead of one shared
"private" tier.** This lets the database security group and route table be more
restrictive than the app tier's (the DB subnets have no route to the internet
at all, not even via NAT) — a defense-in-depth control appropriate for a
finance company's data tier.

**One NAT Gateway per AZ (configurable to single) instead of a single shared
NAT.** Default here is `single_nat_gateway = true` for the dev environment to
control cost; the module supports `false` for one-per-AZ so a NAT Gateway
failure in one AZ doesn't take down egress for the whole app tier. This
trade-off is exposed as a variable specifically so it's visible and deliberate,
not hidden — recommended `false` for staging/production.

**WAF with AWS managed rule groups + a rate-based rule.** Common exploits
(SQLi, generic bad inputs) and basic volumetric abuse are filtered at the edge
before requests reach compute, reducing blast radius and unnecessary
autoscaling churn from bot traffic.

**Secrets Manager for DB credentials, injected into the container via ECS
`secrets` (not environment variables baked into the task definition or image).**
Credentials never appear in the task definition JSON, in `terraform plan`
output as a static string, or in the container image. Rotation can be enabled
later without a code change.

**Terraform module boundaries** (network / security / alb / ecs / rds /
waf / monitoring) mirror how the infrastructure would actually be
changed independently in practice — e.g., the security team can review SG
rules module-by-module, and the RDS module can be swapped for a different
engine without touching networking.

## 4. Portability / reproducibility

- All account-specific values (state bucket name, AWS account ID via
  `container_image`, ACM cert ARN, alert email) are variables, not hardcoded.
- `terraform/bootstrap` is a standalone root module so state-backend creation
  is explicit and separate from the application stack — a new AWS account
  just runs bootstrap once, then points `environments/dev` at it.
- The environment is a single folder (`environments/dev`) intentionally kept
  small so it can be copied to `environments/staging` / `environments/prod`
  with different `.tfvars`, or converted to Terragrunt `terragrunt.hcl` files
  with minimal changes since modules already take all environment-specific
  values as inputs.

## 5. Known simplifications (documented, not hidden)

- **HTTPS is optional** (`certificate_arn` variable) because the assessment
  doesn't provide a real domain to validate an ACM certificate against. The
  ALB module already contains the HTTP→HTTPS redirect logic; supplying a
  validated ACM cert ARN turns it on with no other changes.
- **Single container serves both static frontend and API** for simplicity of
  the demo app; a larger production app would likely split these (e.g.,
  static assets on S3/CloudFront, API on ECS) to reduce compute cost for
  static content. Documented here rather than over-engineered for a counter app.
- **CI/CD pipeline is out of scope for this submission** — `scripts/build_and_push.sh`
  and `scripts/deploy.sh` are provided as the manual/CI-callable equivalent,
  with notes in DEPLOYMENT.md on how they'd map into a GitHub Actions workflow.
