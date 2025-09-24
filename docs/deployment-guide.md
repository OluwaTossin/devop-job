# Deployment Guide

This guide walks you through deploying the DevOps Job Portal from scratch.

## Prerequisites

Before you begin, ensure you have:
- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.0 installed
- Git repository access
- Domain name (optional, for custom URLs)

## Step 1: Initial AWS Setup

### Create an IAM User for Terraform
```bash
# Create IAM user via AWS CLI
aws iam create-user --user-name terraform-devops-job-portal

# Attach required policies
aws iam attach-user-policy --user-name terraform-devops-job-portal \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws iam attach-user-policy --user-name terraform-devops-job-portal \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# Create access keys
aws iam create-access-key --user-name terraform-devops-job-portal
```

### Configure AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

## Step 2: Bootstrap Terraform Backend

Since we're using remote state, we need to create the S3 bucket and DynamoDB table first:

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://terraform-state-devops-job-portal --region eu-west-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-devops-job-portal \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

## Step 3: Deploy Development Environment

### Clone and Configure
```bash
# Clone the repository
git clone <your-repository-url>
cd devop-job

# Copy and customize variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

### Edit terraform.tfvars
```hcl
# terraform/terraform.tfvars
aws_region = "eu-west-1"
project_name = "devops-job-portal"
environment = "dev"
db_username = "dbadmin"
db_password = "YourSecurePassword123!"  # Change this!
allowed_origins = ["*"]
```

### Initialize and Deploy
```bash
cd terraform

# Initialize Terraform
terraform init

# Create and select development workspace
terraform workspace new dev
terraform workspace select dev

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="terraform.tfvars"
```

### Deploy Frontend
```bash
# Get outputs from Terraform
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
API_URL=$(terraform output -raw api_gateway_url)

# Update frontend configuration
cd ../frontend
sed -i "s|https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/dev|$API_URL|g" js/app.js

# Deploy to S3
aws s3 sync . s3://$FRONTEND_BUCKET --delete
```

### Access Your Application
```bash
# Get the website URL
WEBSITE_URL=$(terraform output -raw frontend_website_url)
echo "Your development site is available at: http://$WEBSITE_URL"
```

## Step 4: Deploy Production Environment

### Create Production Variables
```bash
# Create production-specific variables
cp terraform.tfvars terraform.tfvars.prod

# Edit for production settings
nano terraform.tfvars.prod
```

### Production terraform.tfvars.prod
```hcl
aws_region = "eu-west-1"
project_name = "devops-job-portal"
environment = "prod"
db_username = "dbadmin"
db_password = "YourVerySecureProductionPassword123!"
allowed_origins = ["https://yourdomain.com"]  # Replace with your domain
```

### Deploy Production
```bash
# Create and select production workspace
terraform workspace new prod
terraform workspace select prod

# Plan production deployment
terraform plan -var-file="terraform.tfvars.prod"

# Apply (after careful review)
terraform apply -var-file="terraform.tfvars.prod"

# Deploy frontend
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
API_URL=$(terraform output -raw api_gateway_url)

cd ../frontend
sed -i "s|https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/dev|$API_URL|g" js/app.js

aws s3 sync . s3://$FRONTEND_BUCKET --delete
```

## Step 5: Set Up GitHub Actions (Optional)

### Add Repository Secrets
In your GitHub repository, go to Settings > Secrets and add:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-west-1
PROD_DB_PASSWORD=your_production_database_password
```

### Configure Branch Protection
1. Go to Settings > Branches
2. Add branch protection rule for `main`:
   - Require pull request reviews
   - Require status checks (after first workflow run)
   - Restrict pushes to prevent direct commits

### Test Automated Deployment
```bash
# Create develop branch
git checkout -b develop
git push origin develop

# Make a change and push to trigger dev deployment
echo "# Test change" >> README.md
git add README.md
git commit -m "Test automated deployment"
git push origin develop
```

## Step 6: Verify Deployment

### Test Application Functionality
```bash
# Test API endpoints
curl -X GET "https://your-api-gateway-url/applications"

# Test frontend
curl -I "http://your-s3-website-url"

# Test CV submission (use Postman or frontend)
```

### Check Monitoring
1. Go to AWS CloudWatch Console
2. Check the custom dashboard: `devops-job-portal-{env}-dashboard`
3. Review log groups for any errors
4. Verify alarms are configured

### Database Verification
```bash
# Connect to RDS (from EC2 instance or local with proper security group rules)
psql -h your-rds-endpoint -U dbadmin -d jobportal

# Check table creation
\dt

# Verify schema
\d applications
```

## Step 7: Configure Custom Domain (Optional)

### Route 53 Setup
```bash
# Create hosted zone (if you own the domain)
aws route53 create-hosted-zone --name yourdomain.com --caller-reference $(date +%s)

# Get S3 website endpoint
WEBSITE_ENDPOINT=$(terraform output -raw frontend_website_url)

# Create CNAME record pointing to S3 website
# Use AWS Console or CLI to create Route 53 record
```

### SSL Certificate (requires CloudFront)
For HTTPS, you'll need to set up CloudFront distribution with SSL certificate from ACM.

## Step 8: Production Checklist

Before going live with production:

### Security Review
- [ ] Database password changed from default
- [ ] Security groups properly configured
- [ ] S3 bucket policies reviewed
- [ ] IAM roles follow least privilege principle
- [ ] All data encrypted at rest and in transit

### Performance Review
- [ ] Lambda memory allocation optimized
- [ ] Database connections properly managed
- [ ] S3 transfer acceleration enabled (if needed)
- [ ] CloudWatch alarms configured

### Operational Readiness
- [ ] Backup strategy implemented
- [ ] Monitoring dashboards configured
- [ ] Log retention policies set
- [ ] Cost alerts configured
- [ ] Rollback procedures documented

### Testing
- [ ] End-to-end application testing
- [ ] Load testing performed
- [ ] Security testing completed
- [ ] Disaster recovery testing done

## Troubleshooting Common Issues

### Terraform State Lock
```bash
# If state gets locked
terraform force-unlock LOCK_ID
```

### Lambda Function Errors
```bash
# View logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/devops-job-portal"
aws logs tail "/aws/lambda/devops-job-portal-dev-submit-cv" --follow
```

### RDS Connection Issues
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Test connection from Lambda subnet
# Ensure Lambda functions are in same VPC as RDS
```

### S3 Website Not Accessible
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket your-bucket-name

# Check website configuration
aws s3api get-bucket-website --bucket your-bucket-name
```

## Maintenance

### Regular Tasks
- Monitor AWS costs monthly
- Review CloudWatch logs weekly
- Update dependencies quarterly
- Backup verification monthly
- Security patching as needed

### Scaling Considerations
- Monitor Lambda concurrent executions
- Watch RDS connection counts
- Review S3 request metrics
- Consider CloudFront for global users

## Support

For issues:
1. Check CloudWatch logs first
2. Review Terraform plan output
3. Verify AWS service limits
4. Check GitHub Actions logs for CI/CD issues

Remember to always test changes in development before applying to production!