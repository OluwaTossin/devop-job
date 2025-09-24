# Contributing to DevOps Job Portal

Thank you for your interest in contributing to the DevOps Job Portal project! This document provides guidelines for contributing to this educational project.

## Code of Conduct

This project is intended for learning and demonstration purposes. Please be respectful and constructive in all interactions.

## How to Contribute

### Reporting Issues
- Use GitHub Issues to report bugs or suggest features
- Provide clear description and steps to reproduce
- Include environment details (OS, Terraform version, AWS region)

### Making Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/devop-job.git
   cd devop-job
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation if needed

4. **Test your changes**
   ```bash
   # Test Terraform configuration
   terraform fmt
   terraform validate
   terraform plan
   
   # Test frontend changes
   # Open index.html in browser
   
   # Test backend changes
   # Deploy to development environment
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Guidelines

Use conventional commits format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation updates
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

Examples:
- `feat: add email notifications for new applications`
- `fix: resolve RDS connection timeout issue`
- `docs: update deployment guide with new steps`

## Development Guidelines

### Terraform
- Use consistent naming conventions with `local.name_prefix`
- Add appropriate tags to all resources
- Include variable descriptions and validation
- Follow security best practices
- Document resource dependencies

### Frontend
- Maintain mobile-responsive design
- Follow accessibility best practices
- Use semantic HTML
- Keep JavaScript modular and well-commented
- Test across different browsers

### Backend (Lambda)
- Follow Python PEP 8 style guidelines
- Include proper error handling
- Add logging for debugging
- Use environment variables for configuration
- Validate all inputs
- Handle database connections properly

### Documentation
- Update README.md for significant changes
- Add inline code comments
- Update architecture diagrams if needed
- Include examples in documentation

## Testing

### Infrastructure Testing
```bash
# Format check
terraform fmt -check

# Validate configuration
terraform validate

# Security scan (if checkov installed)
checkov -d terraform/

# Plan and review
terraform plan -var="environment=dev"
```

### Application Testing
- Test all form validations
- Verify API endpoints work correctly
- Test file upload functionality
- Verify responsive design
- Check cross-browser compatibility

## Educational Aspects

This project is designed to teach:
- Infrastructure as Code with Terraform
- AWS serverless architecture
- CI/CD with GitHub Actions
- Three-tier application design
- Security best practices
- Modern web development

When contributing, consider:
- Learning value of the change
- Documentation quality
- Code clarity for educational purposes

## Pull Request Process

1. **Ensure your PR**:
   - Has a clear title and description
   - References any related issues
   - Includes necessary documentation updates
   - Passes all checks (if CI is set up)

2. **PR Review**:
   - Maintainers will review your PR
   - Address any requested changes
   - Keep discussions respectful and constructive

3. **Merging**:
   - PRs are typically merged to `develop` first
   - Releases are merged to `main` for production

## Ideas for Contributions

### Beginner-Friendly
- Improve error messages
- Add form field validations
- Update documentation
- Fix typos or formatting issues
- Add more CSS styling
- Improve accessibility

### Intermediate
- Add email notifications
- Implement pagination for admin view
- Add search/filter functionality
- Create API documentation
- Add unit tests
- Implement caching

### Advanced
- Add CloudFront distribution
- Implement blue/green deployments
- Add comprehensive monitoring
- Create backup/restore procedures
- Add multi-region deployment
- Implement advanced security features

## Resources

### Learning Materials
- [Terraform Documentation](https://terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Tools
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://terraform.io/)
- [VS Code](https://code.visualstudio.com/)
- [Postman](https://www.postman.com/) (for API testing)

## Getting Help

- Create an issue for questions
- Check existing documentation first
- Include relevant error messages
- Provide context about your environment

## Recognition

Contributors will be recognized in the project documentation and README. All contributions, no matter how small, are valued and appreciated!

Thank you for helping improve this educational project! 🚀