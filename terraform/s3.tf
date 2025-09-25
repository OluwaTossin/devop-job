# S3 bucket for frontend hosting
resource "aws_s3_bucket" "frontend" {
  bucket = "${local.name_prefix}-frontend"

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [bucket]
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access settings
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket for storing uploaded CVs
resource "aws_s3_bucket" "cv_storage" {
  bucket = "${local.name_prefix}-cv-storage"

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [bucket]
  }
}

# S3 bucket versioning for CV storage
resource "aws_s3_bucket_versioning" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption for CV storage
resource "aws_s3_bucket_server_side_encryption_configuration" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to CV storage
resource "aws_s3_bucket_public_access_block" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note: S3 bucket for Terraform state and DynamoDB table for locking
# are created by the bootstrap script and managed outside of Terraform
# to avoid chicken-and-egg problems