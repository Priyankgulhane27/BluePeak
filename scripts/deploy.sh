#!/usr/bin/env bash
#
# Convenience wrapper around terraform init/plan/apply for the dev environment.
# Assumes terraform/bootstrap has already been applied once and its bucket/
# table names are passed in here.
#
# Usage: ./deploy.sh <state-bucket-name> <lock-table-name> [plan|apply|destroy]

set -euo pipefail

STATE_BUCKET="${1:?Usage: deploy.sh <state-bucket> <lock-table> [plan|apply|destroy]}"
LOCK_TABLE="${2:?Usage: deploy.sh <state-bucket> <lock-table> [plan|apply|destroy]}"
ACTION="${3:-plan}"

cd "$(dirname "$0")/../terraform/environments/dev"

echo ">> terraform init"
terraform init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -reconfigure

case "${ACTION}" in
  plan)
    terraform plan -var-file=terraform.tfvars
    ;;
  apply)
    terraform apply -var-file=terraform.tfvars
    ;;
  destroy)
    terraform destroy -var-file=terraform.tfvars
    ;;
  *)
    echo "Unknown action: ${ACTION}. Use plan|apply|destroy."
    exit 1
    ;;
esac
