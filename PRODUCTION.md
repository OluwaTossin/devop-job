# Production Deployment Guide

This guide covers deploying the DevOps Job Portal to production environment.

## 🏗️ Production Architecture

### Enhanced Production Features
- **High Availability**: Multi-AZ database deployment
- **Security**: Enhanced encryption and security groups
- **Monitoring**: Comprehensive CloudWatch monitoring and alerts
- **Backup**: Automated backups with 7-day retention
- **Performance**: Optimized Lambda memory and timeout settings
- **Scalability**: Auto-scaling enabled for all components

## 🚀 Production Deployment

### Prerequisites
- AWS CLI configured with production credentials
- Terraform >= 1.0
- Appropriate IAM permissions for production resources
- Domain name (optional) for custom URL

### Quick Production Deployment

```bash
# 1. Switch to main branch
git checkout main

# 2. Navigate to project directory
cd /path/to/devop-job

# 3. Run production deployment script
chmod +x scripts/deploy-production.sh
./scripts/deploy-production.sh
```

### Manual Deployment Steps

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Copy production variables
cp terraform.tfvars.prod terraform.tfvars

# 3. Initialize and deploy
terraform init
terraform plan
terraform apply

# 4. Update frontend configuration
# (Script will do this automatically)

# 5. Deploy frontend
aws s3 sync ../frontend s3://$(terraform output -raw frontend_bucket_name) --delete
```

## 🔐 Production Security Setup

### 1. Admin Credentials
```bash
# Generate secure password hash
python3 -c "import hashlib; password = input('Enter admin password: '); print('Hash:', hashlib.sha256(password.encode()).hexdigest())"

# Update production credentials
aws secretsmanager put-secret-value \
  --secret-id devops-job-portal-prod-admin-credentials \
  --secret-string '{"username":"admin","password_hash":"<hash>","jwt_secret":"<secure-jwt-secret>"}' \
  --region eu-west-1
```

### 2. SSL Certificate (Optional)
For custom domain, set up SSL certificate through AWS Certificate Manager:
```bash
# Request certificate
aws acm request-certificate \
  --domain-name your-domain.com \
  --validation-method DNS \
  --region eu-west-1
```

## 📊 Production Monitoring

### CloudWatch Dashboards
The deployment automatically sets up monitoring for:
- Lambda function performance
- API Gateway metrics
- Database performance
- S3 access patterns

### Recommended Alarms
Set up CloudWatch alarms for:
- High error rates (>5%)
- Database connection failures
- Lambda timeout errors
- High response times (>2s)

## 🔧 Production Configuration

### Environment Variables
Production uses optimized settings:
- **Lambda Memory**: 512MB (vs 256MB in dev)
- **Lambda Timeout**: 60s (vs 30s in dev)
- **DB Instance**: db.t3.small (vs db.t3.micro in dev)
- **Multi-AZ**: Enabled for high availability
- **Backup Retention**: 7 days
- **Encryption**: Enabled for all data at rest

### Production Differences from Dev
| Component | Development | Production |
|-----------|-------------|------------|
| Environment | `dev` | `prod` |
| Database | db.t3.micro | db.t3.small |
| Multi-AZ | Disabled | Enabled |
| Backups | 1 day | 7 days |
| Lambda Memory | 256MB | 512MB |
| Monitoring | Basic | Enhanced |

## 🚨 Production Checklist

### Pre-Deployment
- [ ] Review all Terraform configurations
- [ ] Verify AWS credentials and permissions
- [ ] Backup existing production data (if any)
- [ ] Test deployment in staging environment
- [ ] Prepare rollback plan

### Post-Deployment
- [ ] Set up admin credentials
- [ ] Configure monitoring alerts
- [ ] Test all application features
- [ ] Verify database connectivity
- [ ] Check SSL certificate (if using custom domain)
- [ ] Update DNS records (if using custom domain)
- [ ] Document any production-specific configurations

### Security Hardening
- [ ] Review security groups and NACLs
- [ ] Enable AWS CloudTrail for audit logging
- [ ] Set up AWS GuardDuty for threat detection
- [ ] Configure AWS Config for compliance monitoring
- [ ] Enable VPC Flow Logs
- [ ] Review IAM policies and roles

## 🔄 Production Operations

### Backup and Recovery
```bash
# Create manual database snapshot
aws rds create-db-snapshot \
  --db-instance-identifier devops-job-portal-prod-db \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d-%H%M%S)

# List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier devops-job-portal-prod-db
```

### Scaling Operations
```bash
# Scale database instance
aws rds modify-db-instance \
  --db-instance-identifier devops-job-portal-prod-db \
  --db-instance-class db.t3.medium \
  --apply-immediately
```

### Log Monitoring
```bash
# View Lambda logs
aws logs tail /aws/lambda/devops-job-portal-prod-submit-cv --follow

# View API Gateway logs
aws logs tail /aws/apigateway/devops-job-portal-prod --follow
```

## 🆘 Troubleshooting

### Common Production Issues

#### Database Connection Issues
- Verify security groups allow Lambda to RDS access
- Check VPC configuration and subnets
- Validate database credentials in Secrets Manager

#### High Lambda Costs
- Monitor Lambda duration and memory usage
- Optimize code for better performance
- Consider provisioned concurrency for consistent performance

#### API Gateway Timeouts
- Check Lambda function timeout settings
- Monitor database query performance
- Review CloudWatch logs for bottlenecks

### Production Support Commands
```bash
# Check infrastructure status
terraform show | grep -E "(status|state)"

# Monitor API performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Latency \
  --dimensions Name=ApiName,Value=devops-job-portal-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

## 📞 Production Support

### Incident Response
1. Check CloudWatch dashboards for anomalies
2. Review recent deployments or changes
3. Check AWS Service Health Dashboard
4. Review application logs in CloudWatch
5. Verify database connectivity and performance

### Emergency Contacts
- AWS Support: [Your support plan details]
- Database Administrator: [Contact info]
- DevOps Team Lead: [Contact info]

---

**⚠️ Important**: Always test changes in a staging environment before applying to production.