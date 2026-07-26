#!/usr/bin/env bash
#
# Builds the counter app image and pushes it to an ECR repo, creating the
# repo if it doesn't exist. Prints the image URI to use as `container_image`
# in terraform.tfvars.
#
# Usage: ./build_and_push.sh <aws-region> <repo-name>
# Example: ./build_and_push.sh us-east-1 bluepeak-counter

set -euo pipefail

REGION="${1:-us-east-1}"
REPO_NAME="${2:-bluepeak-counter}"
TAG="${3:-latest}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

echo ">> Ensuring ECR repository exists: ${REPO_NAME}"
aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${REGION}" >/dev/null 2>&1 || \
  aws ecr create-repository \
    --repository-name "${REPO_NAME}" \
    --region "${REGION}" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=KMS

echo ">> Authenticating Docker to ECR"
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo ">> Building image"
docker build -t "${REPO_NAME}:${TAG}" ../app

echo ">> Tagging and pushing"
docker tag "${REPO_NAME}:${TAG}" "${ECR_URI}:${TAG}"
docker push "${ECR_URI}:${TAG}"

echo ""
echo "Image pushed successfully:"
echo "  ${ECR_URI}:${TAG}"
echo ""
echo "Set this as 'container_image' in terraform/environments/dev/terraform.tfvars"
