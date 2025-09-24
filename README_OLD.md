# DevOps Engineer Job Portal

## Job Advertisement: Mid-Level DevOps Engineer (Remote)

### About the Role
We are seeking a talented **Mid-Level DevOps Engineer** to join our dynamic team in a fully remote capacity. This role offers an excellent opportunity to work with cutting-edge cloud technologies and modern infrastructure practices.

### Key Responsibilities
- Design and implement AWS cloud infrastructure using Infrastructure as Code (Terraform)
- Maintain and optimize CI/CD pipelines using GitHub Actions
- Manage containerized applications and serverless architectures
- Implement monitoring, logging, and alerting solutions
- Collaborate with development teams to ensure smooth deployment processes
- Maintain security best practices across all environments

### Required Skills
- **Cloud Platforms**: AWS (S3, Lambda, RDS, API Gateway, CloudWatch)
- **Infrastructure as Code**: Terraform, CloudFormation
- **CI/CD**: GitHub Actions, automated testing and deployment
- **Programming**: Python, JavaScript, Bash scripting
- **Databases**: PostgreSQL, MySQL, database design and optimization
- **Monitoring**: CloudWatch, application performance monitoring
- **Security**: AWS IAM, secrets management, security best practices

### Preferred Qualifications
- 3-5 years of experience in DevOps/Cloud Engineering
- AWS certifications (Solutions Architect, Developer, or SysOps)
- Experience with serverless architectures
- Knowledge of frontend technologies (HTML, CSS, JavaScript)
- Experience with autoscaling and load balancing
- Strong problem-solving and communication skills

### What We Offer
- Competitive salary and benefits
- Fully remote work environment
- Professional development opportunities
- Flexible working hours
- Access to latest tools and technologies

---

## Project Architecture

This repository contains a complete three-tier application demonstrating modern DevOps practices:

### Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Database      │
│   (S3 Static    │────│   (Lambda +     │────│   (RDS          │
│   Website)      │    │   API Gateway)  │    │   PostgreSQL)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technologies Used
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Backend**: AWS Lambda (Python), API Gateway
- **Database**: Amazon RDS (PostgreSQL)
- **Infrastructure**: Terraform, AWS S3 (static hosting)
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch, Lambda insights

### Features
- CV submission portal with file upload
- Admin dashboard for viewing applications
- Separate development and production environments
- Automated deployment pipelines
- Auto-scaling Lambda functions
- Secure credential management

## Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- Terraform >= 1.0
- Node.js >= 16
- Python >= 3.9
- GitHub account for Actions

### Quick Setup
1. Clone this repository
2. Configure AWS credentials
3. Initialize Terraform
4. Deploy infrastructure
5. Access the application via S3 static website URL

For detailed setup instructions, see [SETUP.md](./SETUP.md).

## Project Structure
```
devop-job/
├── terraform/              # Infrastructure as Code
│   ├── environments/       # Environment-specific configs
│   ├── modules/            # Reusable Terraform modules
│   └── backend.tf          # Remote state configuration
├── frontend/               # Static website files
│   ├── index.html
│   ├── css/
│   └── js/
├── backend/                # Lambda functions
│   ├── api/                # API endpoints
│   └── requirements.txt
├── .github/                # CI/CD workflows
│   └── workflows/
└── docs/                   # Documentation
```

## Contributing
This project serves as a learning platform for DevOps practices. Feel free to explore, modify, and improve the codebase.

## License
MIT License - See [LICENSE](./LICENSE) for details.