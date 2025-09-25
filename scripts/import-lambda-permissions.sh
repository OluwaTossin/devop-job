#!/usr/bin/env bash
# Import existing Lambda permission statements into Terraform state to avoid 409 ResourceConflict
# Usage:
#   ./scripts/import-lambda-permissions.sh dev|prod
# Requires: terraform, aws cli, initialized backend, and correct AWS credentials
set -euo pipefail

ENVIRONMENT="${1:-}"
if [[ -z "$ENVIRONMENT" || ("$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod") ]]; then
  echo "Usage: $0 dev|prod" >&2
  exit 1
fi

PREFIX="devops-job-portal-${ENVIRONMENT}"
TF_DIR="$(cd "$(dirname "$0")/.." && pwd)/terraform"

pushd "$TF_DIR" >/dev/null

terraform init -upgrade=false 1>/dev/null
terraform workspace select "$ENVIRONMENT" 2>/dev/null || terraform workspace new "$ENVIRONMENT"

# Imports are idempotent and ignored if already in state
terraform state show aws_lambda_permission.submit_cv >/dev/null 2>&1 || terraform import aws_lambda_permission.submit_cv "${PREFIX}-submit-cv/AllowExecutionFromAPIGateway" || true
terraform state show aws_lambda_permission.list_applications >/dev/null 2>&1 || terraform import aws_lambda_permission.list_applications "${PREFIX}-list-applications/AllowExecutionFromAPIGateway" || true
terraform state show aws_lambda_permission.get_application >/dev/null 2>&1 || terraform import aws_lambda_permission.get_application "${PREFIX}-get-application/AllowExecutionFromAPIGateway" || true
terraform state show aws_lambda_permission.admin_login >/dev/null 2>&1 || terraform import aws_lambda_permission.admin_login "${PREFIX}-admin-login/AllowExecutionFromAPIGateway" || true

popd >/dev/null

echo "Imports complete for ${ENVIRONMENT}."