#!/bin/bash

# Simple deployment script for DevOps Job Portal
# This script deploys the development environment

set -e

echo "🚀 Deploying DevOps Job Portal to Development Environment"
echo "Region: eu-west-1"
echo ""

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    echo "❌ Please run this script from the terraform directory"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI is configured"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  Please edit terraform.tfvars and update the database password!"
    echo "   Current file has default values."
fi

# Create or select workspace
echo "🏗️  Setting up development workspace..."
terraform workspace new dev 2>/dev/null || terraform workspace select dev

# Plan deployment
echo "📋 Planning Terraform deployment..."
terraform plan -var="environment=dev" -out=dev.tfplan

echo ""
echo "🎯 Ready to deploy! Review the plan above."
echo "If everything looks good, run:"
echo "   terraform apply dev.tfplan"
echo ""
echo "🔗 After deployment, you can:"
echo "   1. Get the website URL: terraform output frontend_website_url"
echo "   2. Get the API URL: terraform output api_gateway_url"
echo "   3. Deploy frontend: aws s3 sync ../frontend/ s3://\$(terraform output -raw frontend_bucket_name)"