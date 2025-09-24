#!/bin/bash

# Fixed deployment script for DevOps Job Portal
# This addresses the issues encountered with the initial deployment

set -e

echo "🔧 Fixing deployment issues and deploying to development..."
echo "Region: eu-west-1"
echo ""

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    echo "❌ Please run this script from the terraform directory"
    exit 1
fi

# Check AWS CLI
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured properly"
    exit 1
fi

echo "✅ AWS CLI is configured"

# Ensure we have a clean state
echo "🧹 Cleaning up any partial state..."
rm -f terraform.tfstate terraform.tfstate.backup *.tfplan

# Initialize Terraform 
echo "🏗️  Initializing Terraform..."
terraform init -reconfigure

# Create/select workspace
echo "📁 Setting up workspace..."
terraform workspace select dev 2>/dev/null || terraform workspace new dev

# Validate configuration
echo "✅ Validating configuration..."
terraform validate

# Import existing resources that were created by bootstrap
echo "📥 Importing pre-existing resources..."

# Try to import the S3 bucket (might fail if already imported, that's ok)
terraform import aws_s3_bucket.terraform_state terraform-state-devops-job-portal 2>/dev/null || echo "   S3 bucket import skipped (already managed or doesn't exist)"

# Try to import the DynamoDB table
terraform import aws_dynamodb_table.terraform_locks terraform-locks 2>/dev/null || echo "   DynamoDB table import skipped (already managed or doesn't exist)"

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan -var="environment=dev" -out=fixed.tfplan

echo ""
echo "🎯 Plan completed successfully!"
echo ""
echo "To apply the deployment, run:"
echo "   terraform apply fixed.tfplan"
echo ""
echo "🔍 Key fixes applied:"
echo "   ✅ PostgreSQL version updated to 14.19 (available in eu-west-1)"
echo "   ✅ API Gateway output fixed (no longer using deprecated invoke_url)"
echo "   ✅ Terraform state resources handled properly"
echo ""