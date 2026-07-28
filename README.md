# BluePeak Technologies — AWS Cloud-Native Migration (Assessment Submission)

A private, 3-tier, highly available, auto-scaling AWS architecture,
provisioned entirely with Terraform, hosting an Increment/Decrement counter
app whose count is persisted in a managed RDS PostgreSQL database.


## Quick start

Full details in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md). Short version:

```bash
# 1. One-time backend bootstrap
cd terraform/bootstrap && terraform init && terraform apply -var="state_bucket_name=bluepeak-tf-state-<your-unique-suffix>"

# 2. Build & push the app image
cd ../../scripts && ./build_and_push.sh us-east-1 bluepeak-counter v1

# 3. Configure and deploy
./scripts/deploy.sh <state-bucket-name> <lock-table-name> apply

# 4. Visit the app
terraform output app_url
```

## Design highlights

- **Genuinely 3-tier**: the counter app's state is persisted in RDS.
- **Scales automatically with business-hours demand**: ECS Application Auto
  Scaling handles the app tier (CPU + ALB request count); the RDS instance
  autoscales storage as data grows (`max_allocated_storage`), 
- **Least-privilege networking**: DB subnets have zero internet route;
  security groups only allow traffic from the tier directly above them.
- **No hardcoded secrets**: DB password is Terraform-generated, lives only in
  Secrets Manager, injected into the container at runtime.
- **Portable**: every account-specific value is a variable.
