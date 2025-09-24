# DevOps Job Portal - Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed and configured:

### Required Tools
- **AWS CLI** (v2.x): `aws --version`
- **Terraform** (v1.0+): `terraform version`
- **Node.js** (v16+): `node --version`
- **Python** (v3.9+): `python --version`
- **Git**: `git --version`

### AWS Account Setup
1. Create an AWS account if you don't have one
2. Create an IAM user with programmatic access
3. Attach the following policies:
   - `AmazonS3FullAccess`
   - `AmazonRDSFullAccess`
   - `AWSLambdaFullAccess`
   - `AmazonAPIGatewayAdministrator`
   - `CloudWatchFullAccess`
   - `IAMFullAccess` (for creating roles)

### Configure AWS Credentials

#### Option 1: AWS CLI (Recommended)
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `eu-west-1`)
- Default output format: `json`

#### Option 2: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=eu-west-1
```

## Installation Steps

### 1. Clone the Repository
```bash
git clone <repository-url>
cd devop-job
```

### 2. Initialize Terraform Backend
```bash
cd terraform
terraform init
```

### 3. Create Terraform Workspaces
```bash
# Create development environment
terraform workspace new dev

# Create production environment
terraform workspace new prod

# Switch to development for initial setup
terraform workspace select dev
```

### 4. Configure Variables
Copy the example variables file and customize:
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
```hcl
aws_region = "eu-west-1"
project_name = "devops-job-portal"
environment = "dev"
```

### 5. Deploy Infrastructure

#### Development Environment
```bash
terraform workspace select dev
terraform plan
terraform apply
```

#### Production Environment
```bash
terraform workspace select prod
terraform apply -var="environment=prod"
```

### 6. Install Backend Dependencies
```bash
cd ../backend
pip install -r requirements.txt
```

### 7. Deploy Lambda Functions
The Lambda functions will be automatically deployed via Terraform, but for local development:
```bash
cd backend
python -m pytest tests/  # Run tests
```

## Accessing the Application

After successful deployment, Terraform will output the S3 website URLs:
- **Development**: `http://devops-job-portal-dev-frontend.s3-website-eu-west-1.amazonaws.com`
- **Production**: `http://devops-job-portal-prod-frontend.s3-website-eu-west-1.amazonaws.com`

## Environment Management

### Switching Between Environments
```bash
# Switch to development
terraform workspace select dev
terraform plan

# Switch to production
terraform workspace select prod
terraform plan
```

### Environment Variables
Each environment uses separate:
- S3 buckets
- RDS instances
- Lambda functions
- API Gateway endpoints

## GitHub Actions Setup

### 1. Add Repository Secrets
In your GitHub repository, go to Settings > Secrets and add:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 2. Configure Workflows
The GitHub Actions workflows are pre-configured in `.github/workflows/`:
- `deploy-dev.yml` - Deploys to development on push to `develop` branch
- `deploy-prod.yml` - Deploys to production on push to `main` branch

## Monitoring and Logs

### CloudWatch Logs
- Lambda function logs: `/aws/lambda/devops-job-portal-{env}-{function-name}`
- API Gateway logs: `/aws/apigateway/devops-job-portal-{env}`

### CloudWatch Metrics
Monitor the following metrics:
- Lambda invocations and duration
- API Gateway request count and latency
- RDS connections and performance

### Accessing Logs
```bash
# Via AWS CLI
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/devops-job-portal"

# Via AWS Console
# Navigate to CloudWatch > Log groups
```

## Database Access

### RDS Connection
```bash
# Get RDS endpoint from Terraform output
terraform output rds_endpoint

# Connect using psql (PostgreSQL)
psql -h <rds-endpoint> -U dbadmin -d jobportal
```

### Database Schema
The database schema is automatically created by the Lambda functions on first run.

## Troubleshooting

### Common Issues

1. **Terraform State Lock**
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **Lambda Deployment Errors**
   - Check CloudWatch logs
   - Verify IAM permissions
   - Ensure dependencies are included

3. **S3 Website Not Accessible**
   - Verify bucket policy allows public read
   - Check bucket website configuration
   - Ensure index.html exists

4. **RDS Connection Issues**
   - Verify security group rules
   - Check VPC configuration
   - Confirm database credentials

### Getting Help
- Check AWS CloudWatch logs
- Review Terraform plan output
- Verify AWS permissions
- Ensure all prerequisites are met

## Cleanup

To destroy the infrastructure:
```bash
# Development environment
terraform workspace select dev
terraform destroy

# Production environment
terraform workspace select prod
terraform destroy

# Delete workspaces
terraform workspace select default
terraform workspace delete dev
terraform workspace delete prod
```

## Next Steps
1. Customize the frontend styling
2. Add additional API endpoints
3. Implement email notifications
4. Add file upload validation
5. Configure custom domain (optional)