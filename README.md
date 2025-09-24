# DevOps Job Portal

A secure, scalable job portal application built on AWS with modern web technologies. This project demonstrates best practices in cloud architecture, infrastructure as code, and full-stack development.

## 🏗️ Architecture Overview

The DevOps Job Portal is built using a modern 3-tier architecture on AWS:

### **Frontend Tier**
- **Technology**: HTML5, CSS3, JavaScript (Vanilla)
- **Hosting**: AWS S3 with Static Website Hosting
- **Features**: Responsive design, admin authentication modal, file uploads

### **Application Tier**
- **Technology**: AWS Lambda (Python 3.9), API Gateway
- **Authentication**: JWT-based admin authentication
- **Functions**: 
  - `submit_cv`: Handle job application submissions
  - `list_applications`: Retrieve applications with pagination/filtering
  - `get_application`: Fetch individual application details
  - `admin_login`: Secure admin authentication

### **Data Tier**
- **Database**: AWS RDS PostgreSQL 14.19
- **File Storage**: AWS S3 for CV uploads
- **Secrets**: AWS Secrets Manager for credentials

## 🚀 Features

### **Public Features**
- ✅ Job application submission form
- ✅ CV file upload (PDF, DOC, DOCX)
- ✅ Responsive mobile-friendly design
- ✅ Real-time form validation
- ✅ Success/error notifications

### **Admin Features** 🔒
- ✅ Secure JWT-based authentication
- ✅ Application management dashboard
- ✅ Pagination and filtering
- ✅ Individual application details
- ✅ Session management with auto-logout

### **Security Features**
- ✅ SHA256 password hashing
- ✅ JWT token authentication (24h expiry)
- ✅ AWS Secrets Manager integration
- ✅ HTTPS enforcement
- ✅ CORS configuration
- ✅ Server-side encryption for files

## 🌐 Live Demo

**Website URL**: http://devops-job-portal-dev-frontend.s3-website-eu-west-1.amazonaws.com

**Admin Credentials**:
- Username: `admin`
- Password: `Admin123!@#`

## 📋 Prerequisites

Before deploying this project, ensure you have:

- **AWS Account** with appropriate permissions
- **AWS CLI** configured with credentials
- **Terraform** >= 1.0 installed
- **Python** 3.9+ for local development

## 🛠️ Quick Deployment

### Step 1: Clone and Deploy
```bash
git clone <repository-url>
cd devop-job/terraform
terraform init
terraform apply -auto-approve
```

### Step 2: Set Admin Credentials
```bash
# Generate password hash
python3 -c "import hashlib; print(hashlib.sha256('YourPassword'.encode()).hexdigest())"

# Update credentials in AWS Secrets Manager
aws secretsmanager put-secret-value \
  --secret-id devops-job-portal-dev-admin-credentials \
  --secret-string '{"username":"admin","password_hash":"<generated-hash>","jwt_secret":"your-jwt-secret"}' \
  --region eu-west-1
```

### Step 3: Deploy Frontend
```bash
cd ../frontend
aws s3 sync . s3://devops-job-portal-dev-frontend --delete
```

## 📁 Project Structure

```
devop-job/
├── backend/                    # Lambda functions
│   ├── admin_login.py         # Admin authentication
│   ├── get_application.py     # Application retrieval  
│   ├── list_applications.py   # Application listing
│   └── submit_cv.py           # Application submission
├── frontend/                   # Web interface
│   ├── css/styles.css         # Styling
│   ├── js/app.js              # JavaScript logic
│   └── index.html             # Main page
└── terraform/                  # Infrastructure as Code
    ├── main.tf                # Provider config
    ├── variables.tf           # Variables
    ├── vpc.tf                 # Networking
    ├── rds.tf                 # Database
    ├── lambda.tf              # Functions
    ├── api_gateway.tf         # API endpoints
    ├── s3.tf                  # Storage
    ├── admin_auth.tf          # Authentication
    └── monitoring.tf          # Logging/Monitoring
```

## 🎯 API Endpoints

### Public Endpoints
- `POST /applications` - Submit job application
- `OPTIONS /applications` - CORS preflight

### Admin Endpoints 🔒
- `POST /admin/login` - Admin authentication
- `GET /applications` - List applications (paginated)
- `GET /applications/{id}` - Get application details

### Query Parameters
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 50)  
- `email`: Filter by email
- `experience`: Filter by experience level
- `date_from` / `date_to`: Date range filter

## 🔐 Security Implementation

### Authentication & Authorization
- JWT tokens for admin sessions (24h expiry)
- SHA256 password hashing
- AWS Secrets Manager for credentials
- Session persistence and management

### Data Protection  
- Server-side encryption (S3)
- Database encryption at rest
- VPC isolation
- Private subnets for sensitive resources

### Network Security
- HTTPS enforcement
- CORS configuration
- Security groups with minimal access
- API Gateway rate limiting

## 📊 Monitoring & Observability

### CloudWatch Integration
- Lambda execution logs
- API Gateway access logs  
- Database performance metrics
- Custom application metrics

### Key Metrics Tracked
- Application submission rates
- Admin login attempts
- API response times
- Error rates and patterns

## 🚀 Production Readiness

This project includes production-ready features:

### ✅ Implemented
- Comprehensive error handling
- Structured logging
- Security best practices
- Scalable architecture
- Infrastructure as Code
- Automated deployments

### 🔄 Future Enhancements
- Rate limiting and throttling
- Multi-factor authentication
- Advanced analytics dashboard
- Email notifications
- File scanning/validation
- Backup and disaster recovery

## 🔧 Configuration

### Environment Variables
All configuration is managed through Terraform and AWS services:

- Database connections via RDS
- File storage via S3
- Secrets via Secrets Manager
- Authentication via JWT tokens

### Database Schema
```sql
applications (
    id UUID PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL, 
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    experience VARCHAR(50) NOT NULL,
    location VARCHAR(255),
    skills TEXT,
    cover_letter TEXT,
    cv_file_path VARCHAR(500),
    submitted_at TIMESTAMP DEFAULT NOW()
)
```

## 🆘 Troubleshooting

### Common Issues

**Lambda Function Errors:**
```bash
aws logs tail /aws/lambda/devops-job-portal-dev-function-name --follow
```

**Database Connection Issues:**
- Verify security group rules
- Check VPC configuration  
- Validate credentials in Secrets Manager

**Admin Login Failing:**
- Verify password hash generation
- Check JWT secret in Secrets Manager
- Review authentication logs

### Debug Commands
```bash
# Check Terraform state
terraform show

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/devops"

# Test API endpoints
curl -X POST https://api-url/dev/applications -d '{"test":"data"}'
```

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Create Pull Request

---

**🎯 Built with modern DevOps practices and cloud-native technologies**