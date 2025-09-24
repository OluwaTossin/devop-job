"""
DevOps Job Portal - CV Submission Lambda Function

This Lambda function handles job application submissions including:
- CV file uploads to S3
- Application data storage in PostgreSQL
- Input validation and error handling
- Database schema initialization

Author: DevOps Job Portal Team
Date: September 2025
"""

import json
import os
import base64
import boto3
import psycopg2
from datetime import datetime
import uuid
import logging
import re

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS services
s3 = boto3.client('s3')

# Database connection parameters from environment variables
DB_HOST = os.environ['DB_HOST']
DB_PORT = os.environ['DB_PORT']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']
S3_BUCKET = os.environ['S3_BUCKET']

# Standard CORS headers for all responses
CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
}

def get_db_connection():
    """
    Create and return a PostgreSQL database connection.
    
    Returns:
        psycopg2.connection: Active database connection
        
    Raises:
        psycopg2.Error: If connection fails
    """
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

def initialize_database():
    """
    Initialize database schema if it doesn't exist.
    Creates the applications table and necessary indexes.
    
    Raises:
        Exception: If database initialization fails
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create applications table if it doesn't exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS applications (
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
            )
        """)
        
        # Create indexes for performance
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_applications_email 
            ON applications(email)
        """)
        
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_applications_submitted_at 
            ON applications(submitted_at DESC)
        """)
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info("Database initialized successfully")
        
    except Exception as e:
        logger.error(f"Database initialization error: {str(e)}")
        raise

def upload_cv_to_s3(cv_data, file_name, file_type, application_id):
    """
    Upload CV file to S3 with proper encryption and metadata.
    
    Args:
        cv_data (str): Base64 encoded file data
        file_name (str): Original filename
        file_type (str): MIME type of the file
        application_id (str): Unique application identifier
        
    Returns:
        str: S3 object key of uploaded file
        
    Raises:
        Exception: If upload fails
    """
    try:
        # Decode base64 data
        file_content = base64.b64decode(cv_data)
        
        # Generate unique file name with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_extension = file_name.split('.')[-1] if '.' in file_name else 'pdf'
        s3_key = f"cvs/{application_id}_{timestamp}.{file_extension}"
        
        # Upload to S3 with encryption
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=file_content,
            ContentType=file_type,
            ServerSideEncryption='AES256',
            Metadata={
                'original_name': file_name,
                'application_id': str(application_id),
                'uploaded_at': datetime.now().isoformat()
            }
        )
        
        logger.info(f"CV uploaded successfully: {s3_key}")
        return s3_key
        
    except Exception as e:
        logger.error(f"S3 upload error: {str(e)}")
        raise

def create_error_response(status_code, message):
    """
    Create a standardized error response.
    
    Args:
        status_code (int): HTTP status code
        message (str): Error message
        
    Returns:
        dict: Lambda response object
    """
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json.dumps({'message': message})
    }

def validate_email(email):
    """
    Validate email format using regex.
    
    Args:
        email (str): Email address to validate
        
    Returns:
        bool: True if valid, False otherwise
    """
    email_pattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$'
    return bool(re.match(email_pattern, email))

def lambda_handler(event, context):
    """
    Main Lambda handler for CV submission.
    
    Args:
        event (dict): Lambda event object
        context (object): Lambda context object
        
    Returns:
        dict: HTTP response object
    """
    try:
        # Initialize database
        initialize_database()
        
        # Parse request body
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        logger.info(f"Received application submission: {body.get('email', 'unknown')}")
        
        # Validate required fields
        required_fields = ['firstName', 'lastName', 'email', 'experience', 'skills']
        missing_fields = [field for field in required_fields if not body.get(field)]
        
        if missing_fields:
            return create_error_response(400, f'Missing required fields: {", ".join(missing_fields)}')
        
        # Validate email format
        if not validate_email(body['email']):
            return create_error_response(400, 'Invalid email format')
        
        # Generate application ID
        application_id = str(uuid.uuid4())
        
        # Handle CV upload if provided
        cv_file_path = None
        if body.get('cv') and body.get('cvFileName'):
            try:
                cv_file_path = upload_cv_to_s3(
                    body['cv'], 
                    body['cvFileName'], 
                    body.get('cvFileType', 'application/pdf'),
                    application_id
                )
            except Exception as e:
                logger.error(f"CV upload failed: {str(e)}")
                return create_error_response(500, 'Failed to upload CV file')
        
        # Insert application into database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO applications (
                id, first_name, last_name, email, phone, experience, 
                location, skills, cover_letter, cv_file_path, 
                cv_file_name, cv_file_type
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            application_id,
            body['firstName'],
            body['lastName'],
            body['email'],
            body.get('phone'),
            body['experience'],
            body.get('location'),
            body['skills'],
            body.get('coverLetter'),
            cv_file_path,
            body.get('cvFileName'),
            body.get('cvFileType')
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"Application saved successfully: {application_id}")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': CORS_HEADERS,
            'body': json.dumps({
                'message': 'Application submitted successfully',
                'application_id': application_id,
                'submitted_at': datetime.now().isoformat()
            })
        }
        
    except psycopg2.Error as db_error:
        logger.error(f"Database error: {str(db_error)}")
        return create_error_response(500, 'Database error occurred')
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return create_error_response(500, 'Internal server error')