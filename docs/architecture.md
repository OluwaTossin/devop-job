# DevOps Engineer Job Portal - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 AWS Cloud                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐          │
│  │   CloudWatch    │     │   API Gateway   │     │   Lambda Funcs  │          │
│  │   Monitoring    │     │                 │     │                 │          │
│  │   & Logging     │     │  POST /apps     │────▶│  submit_cv.py   │          │
│  └─────────────────┘     │  GET  /apps     │────▶│  list_apps.py   │          │
│           │               │  GET  /apps/:id │────▶│  get_app.py     │          │
│           │               └─────────────────┘     └─────────────────┘          │
│           │                        │                       │                   │
│           │                        │                       │                   │
│  ┌─────────────────┐               │              ┌─────────────────┐          │
│  │   S3 Buckets    │               │              │   RDS Database  │          │
│  │                 │               │              │   PostgreSQL    │          │
│  │  frontend-site  │◀──────────────┘              │                 │          │
│  │  cv-storage     │                              │  Applications   │          │
│  │  terraform-state│                              │  Table          │          │
│  └─────────────────┘                              └─────────────────┘          │
│           │                                                 │                   │
│           │                        ┌─────────────────┐     │                   │
│           │                        │       VPC       │     │                   │
│           │                        │                 │     │                   │
│           └────────────────────────▶│  Private Nets   │─────┘                   │
│                                    │  Public Nets    │                         │
│                                    │  NAT Gateways   │                         │
│                                    │  Route Tables   │                         │
│                                    └─────────────────┘                         │
└─────────────────────────────────────────────────────────────────────────────────┘

    ▲                                                                      ▲
    │                                                                      │
    │                                                                      │
    │                            Internet                                  │
    │                                                                      │
    │                                                                      │
    ▼                                                                      ▼

┌─────────────────┐                                          ┌─────────────────┐
│    End Users    │                                          │   Developers    │
│                 │                                          │                 │
│  Job Seekers    │                                          │  GitHub Actions │
│  Recruiters     │                                          │  CI/CD Pipeline │
│  Admin Users    │                                          │  Terraform      │
└─────────────────┘                                          └─────────────────┘
```

## Three-Tier Architecture

### 1. Presentation Layer (Frontend)
- **Technology**: HTML5, CSS3, JavaScript (ES6+)
- **Hosting**: Amazon S3 Static Website
- **Features**:
  - Responsive job application form
  - CV upload functionality
  - Admin dashboard for viewing applications
  - Real-time form validation
  - Mobile-responsive design

### 2. Application Layer (Backend)
- **Technology**: AWS Lambda (Python 3.9)
- **API**: REST API via AWS API Gateway
- **Functions**:
  - `submit_cv.py`: Handles job application submissions
  - `list_applications.py`: Retrieves paginated application lists
  - `get_application.py`: Fetches individual application details
- **Features**:
  - Automatic scaling
  - Serverless architecture
  - CORS support
  - Input validation
  - Error handling

### 3. Data Layer (Database)
- **Technology**: Amazon RDS (PostgreSQL 14)
- **Configuration**: Multi-AZ deployment in production
- **Schema**:
  ```sql
  CREATE TABLE applications (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      first_name VARCHAR(100) NOT NULL,
      last_name VARCHAR(100) NOT NULL,
      email VARCHAR(255) NOT NULL,
      phone VARCHAR(20),
      experience VARCHAR(50) NOT NULL,
      location VARCHAR(255),
      skills TEXT,
      cover_letter TEXT,
      cv_file_path VARCHAR(500),
      cv_file_name VARCHAR(255),
      cv_file_type VARCHAR(100),
      submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  ```

## Infrastructure Components

### Networking
- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **Subnets**: 
  - Public subnets for NAT Gateways and Internet Gateway
  - Private subnets for RDS and Lambda functions
- **Security Groups**: Restrictive rules for database access
- **NAT Gateways**: For Lambda internet access

### Storage
- **S3 Buckets**:
  - Frontend hosting bucket (public read access)
  - CV storage bucket (private, encrypted)
  - Terraform state bucket (versioned, encrypted)
- **RDS Storage**: Encrypted GP2 storage with automated backups

### Security
- **IAM Roles**: Least privilege access for Lambda functions
- **Encryption**: At-rest and in-transit encryption
- **Secrets Management**: Environment variables for sensitive data
- **Access Control**: API Gateway CORS configuration

### Monitoring & Logging
- **CloudWatch**:
  - Lambda function logs and metrics
  - API Gateway access logs
  - RDS performance monitoring
  - Custom dashboards
- **Alarms**:
  - Lambda error rates and duration
  - RDS CPU and connection monitoring
  - API Gateway error rates

## Deployment Architecture

### Environments
1. **Development** (`dev`)
   - Smaller instance sizes
   - Shorter log retention
   - Basic monitoring
   - Auto-deploy from `develop` branch

2. **Production** (`prod`)
   - Production-ready instance sizes
   - Extended log retention
   - Enhanced monitoring and alerting
   - Manual approval for deployments
   - Provisioned concurrency for Lambda

### CI/CD Pipeline
```
Developer Push → GitHub → Actions → Terraform → AWS Deploy → Tests
     │              │         │          │          │          │
     ▼              ▼         ▼          ▼          ▼          ▼
   Code           Lint     Package    Validate   Deploy     Verify
   Changes        Test     Lambda     Plan       Apply      Health
```

## Scaling Strategy

### Auto-Scaling Components
1. **Lambda Functions**:
   - Concurrent executions scale automatically
   - Provisioned concurrency in production
   - Reserved concurrency limits to prevent over-scaling

2. **RDS**:
   - Read replicas for high-read workloads
   - Connection pooling via RDS Proxy (optional)
   - Storage auto-scaling enabled

3. **S3**:
   - Automatically scales with demand
   - Transfer acceleration for global users

### Performance Optimization
- Lambda function optimization (memory allocation)
- Database indexing on frequently queried fields
- S3 transfer acceleration
- API Gateway caching (configurable)

## Security Considerations

### Data Protection
- All data encrypted at rest and in transit
- Personal data stored in compliance with privacy regulations
- CV files stored in private S3 bucket with restricted access

### Access Control
- IAM roles with minimal required permissions
- VPC security groups restrict database access
- API rate limiting to prevent abuse

### Monitoring & Alerting
- Real-time monitoring of all components
- Automated alerts for security and performance issues
- Centralized logging for audit trails

## Disaster Recovery

### Backup Strategy
- RDS automated backups with point-in-time recovery
- S3 versioning for all objects
- Terraform state stored remotely with locking

### Recovery Procedures
- Cross-region replication for critical data
- Infrastructure as Code enables rapid reconstruction
- Documented rollback procedures

## Cost Optimization

### Resource Sizing
- Right-sized instances based on environment
- Serverless architecture reduces idle costs
- S3 lifecycle policies for cost management

### Monitoring
- CloudWatch cost monitoring
- AWS Cost Explorer integration
- Budget alerts for cost control

This architecture provides a robust, scalable, and secure platform for the DevOps job portal while maintaining cost efficiency and operational simplicity.