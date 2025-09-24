#!/bin/bash

# Bootstrap script for DevOps Job Portal
# This script creates the required S3 bucket and DynamoDB table for Terraform remote state

set -e

REGION="eu-west-1"
BUCKET_NAME="terraform-state-devops-job-portal"
DYNAMODB_TABLE="terraform-locks"

echo "🚀 Bootstrapping AWS resources for Terraform remote state..."
echo "Region: $REGION"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI is configured"

# Create S3 bucket for Terraform state
echo "📦 Creating S3 bucket: $BUCKET_NAME"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    echo "✅ S3 bucket created: $BUCKET_NAME"
else
    echo "ℹ️  S3 bucket already exists: $BUCKET_NAME"
fi

# Enable versioning on the bucket
echo "🔄 Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "✅ Versioning enabled"

# Enable server-side encryption
echo "🔒 Enabling server-side encryption"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo "✅ Encryption enabled"

# Block public access
echo "🔐 Blocking public access"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✅ Public access blocked"

# Create DynamoDB table for state locking
echo "🗄️  Creating DynamoDB table: $DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" > /dev/null 2>&1; then
    echo "ℹ️  DynamoDB table already exists: $DYNAMODB_TABLE"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo "✅ DynamoDB table created: $DYNAMODB_TABLE"
fi

echo ""
echo "🎉 Bootstrap complete! You can now run:"
echo "   cd terraform"
echo "   terraform init"
echo "   terraform workspace new dev"
echo "   terraform plan"
echo ""
echo "📋 Resources created:"
echo "   S3 Bucket: s3://$BUCKET_NAME (in $REGION)"
echo "   DynamoDB Table: $DYNAMODB_TABLE (in $REGION)"
echo ""
echo "💡 Next steps:"
echo "   1. Copy terraform.tfvars.example to terraform.tfvars"
echo "   2. Customize the variables in terraform.tfvars"
echo "   3. Run: terraform apply"