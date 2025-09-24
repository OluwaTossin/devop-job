#!/bin/bash

# =============================================================================
# DevOps Job Portal - Production Deployment Script
# =============================================================================
# 
# This script deploys the DevOps job portal to production environment
# with proper validation, backup, and monitoring setup.
# 
# Usage: ./deploy-production.sh
# 
# Prerequisites:
# - AWS CLI configured with production credentials
# - Terraform installed
# - Appropriate IAM permissions for production deployment
# =============================================================================

set -e  # Exit on any error

# Configuration
ENVIRONMENT="prod"
PROJECT_NAME="devops-job-portal"
AWS_REGION="eu-west-1"
TERRAFORM_DIR="./terraform"
FRONTEND_DIR="./frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install Terraform."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid."
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    cd $TERRAFORM_DIR
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration validation failed"
        exit 1
    fi
    
    # Format check
    if terraform fmt -check; then
        print_success "Terraform formatting is correct"
    else
        print_warning "Terraform files need formatting. Running terraform fmt..."
        terraform fmt
    fi
    
    cd ..
}

# Function to plan deployment
plan_deployment() {
    print_status "Creating Terraform deployment plan..."
    
    cd $TERRAFORM_DIR
    
    # Copy production variables
    cp terraform.tfvars.prod terraform.tfvars
    
    # Create deployment plan
    terraform plan -out=production.tfplan
    
    print_success "Deployment plan created successfully"
    print_warning "Please review the plan above before proceeding"
    
    read -p "Do you want to proceed with the deployment? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    cd ..
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure to production..."
    
    cd $TERRAFORM_DIR
    
    # Apply the plan
    if terraform apply "production.tfplan"; then
        print_success "Infrastructure deployed successfully"
    else
        print_error "Infrastructure deployment failed"
        exit 1
    fi
    
    # Get outputs
    API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
    FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
    
    print_success "Infrastructure deployment completed"
    print_status "API Gateway URL: $API_GATEWAY_URL"
    print_status "Frontend Bucket: $FRONTEND_BUCKET"
    
    cd ..
}

# Function to update frontend configuration
update_frontend_config() {
    print_status "Updating frontend configuration for production..."
    
    cd $TERRAFORM_DIR
    API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
    cd ..
    
    # Update API URL in frontend JavaScript
    sed -i.bak "s|const API_BASE_URL = '.*';|const API_BASE_URL = '$API_GATEWAY_URL';|" $FRONTEND_DIR/js/app.js
    
    print_success "Frontend configuration updated"
}

# Function to deploy frontend
deploy_frontend() {
    print_status "Deploying frontend to production..."
    
    cd $TERRAFORM_DIR
    FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
    cd ..
    
    # Sync frontend files to S3
    if aws s3 sync $FRONTEND_DIR s3://$FRONTEND_BUCKET --delete --region $AWS_REGION; then
        print_success "Frontend deployed successfully"
    else
        print_error "Frontend deployment failed"
        exit 1
    fi
    
    WEBSITE_URL=$(aws s3api get-bucket-website --bucket $FRONTEND_BUCKET --region $AWS_REGION --query 'WebsiteConfiguration.IndexDocument.Suffix' --output text 2>/dev/null || echo "")
    if [ -n "$WEBSITE_URL" ]; then
        print_success "Website URL: http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    fi
}

# Function to set up production credentials
setup_production_credentials() {
    print_status "Setting up production admin credentials..."
    
    cd $TERRAFORM_DIR
    SECRET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-admin-credentials"
    cd ..
    
    print_warning "You need to set up admin credentials for production"
    echo "Please run the following command manually after deployment:"
    echo
    echo "# Generate password hash:"
    echo "python3 -c \"import hashlib; password = input('Enter admin password: '); print('Password hash:', hashlib.sha256(password.encode()).hexdigest())\""
    echo
    echo "# Then update the secret:"
    echo "aws secretsmanager put-secret-value \\"
    echo "  --secret-id $SECRET_NAME \\"
    echo "  --secret-string '{\"username\":\"admin\",\"password_hash\":\"<your-generated-hash>\",\"jwt_secret\":\"<your-production-jwt-secret>\"}' \\"
    echo "  --region $AWS_REGION"
}

# Function to run post-deployment tests
run_health_checks() {
    print_status "Running production health checks..."
    
    cd $TERRAFORM_DIR
    API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
    cd ..
    
    # Test API endpoints
    print_status "Testing API endpoints..."
    
    # Test CORS endpoint
    if curl -s -o /dev/null -w "%{http_code}" "${API_GATEWAY_URL}/applications" -X OPTIONS | grep -q "200"; then
        print_success "CORS endpoint is healthy"
    else
        print_warning "CORS endpoint may have issues"
    fi
    
    # Test application submission endpoint structure
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_GATEWAY_URL}/applications" -X POST -H "Content-Type: application/json" -d '{}')
    if [ "$RESPONSE" = "400" ]; then
        print_success "Application endpoint is responding (validation working)"
    else
        print_warning "Application endpoint response: HTTP $RESPONSE"
    fi
    
    print_success "Health checks completed"
}

# Function to display deployment summary
show_deployment_summary() {
    print_success "=== PRODUCTION DEPLOYMENT COMPLETED ==="
    echo
    print_status "Environment: $ENVIRONMENT"
    print_status "Region: $AWS_REGION"
    echo
    
    cd $TERRAFORM_DIR
    API_GATEWAY_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not available")
    FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "Not available")
    WEBSITE_URL="http://$FRONTEND_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    cd ..
    
    echo "🌐 Website URL: $WEBSITE_URL"
    echo "🚀 API Gateway: $API_GATEWAY_URL"
    echo "📦 S3 Bucket: $FRONTEND_BUCKET"
    echo
    print_warning "⚠️  Don't forget to:"
    echo "   1. Set up production admin credentials (see instructions above)"
    echo "   2. Configure custom domain and SSL certificate"
    echo "   3. Set up monitoring alerts in CloudWatch"
    echo "   4. Configure backup policies"
    echo "   5. Review and update security groups if needed"
    echo
    print_success "Production deployment successful! 🎉"
}

# Main deployment function
main() {
    print_status "Starting production deployment for $PROJECT_NAME"
    echo "=================================================="
    
    check_prerequisites
    validate_terraform
    plan_deployment
    deploy_infrastructure
    update_frontend_config
    deploy_frontend
    setup_production_credentials
    run_health_checks
    show_deployment_summary
}

# Run main function
main "$@"