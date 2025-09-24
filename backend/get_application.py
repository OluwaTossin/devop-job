import json
import os
import psycopg2
import boto3
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS services
s3 = boto3.client('s3')

# Database connection parameters
DB_HOST = os.environ['DB_HOST']
DB_PORT = os.environ['DB_PORT']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']
S3_BUCKET = os.environ['S3_BUCKET']

def get_db_connection():
    """Create database connection"""
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

def generate_presigned_url(s3_key, expiration=3600):
    """Generate a presigned URL for S3 object"""
    try:
        response = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': s3_key},
            ExpiresIn=expiration
        )
        return response
    except Exception as e:
        logger.error(f"Error generating presigned URL: {str(e)}")
        return None

def lambda_handler(event, context):
    """Main Lambda handler for getting single application"""
    try:
        # Get application ID from path parameters
        path_params = event.get('pathParameters', {}) or {}
        application_id = path_params.get('id')
        
        if not application_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
                },
                'body': json.dumps({
                    'message': 'Application ID is required'
                })
            }
        
        logger.info(f"Fetching application: {application_id}")
        
        # Query database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                id,
                first_name,
                last_name,
                email,
                phone,
                experience,
                location,
                skills,
                cover_letter,
                cv_file_path,
                cv_file_name,
                cv_file_type,
                submitted_at,
                created_at,
                updated_at
            FROM applications
            WHERE id = %s
        """, (application_id,))
        
        row = cursor.fetchone()
        
        if not row:
            cursor.close()
            conn.close()
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
                },
                'body': json.dumps({
                    'message': 'Application not found'
                })
            }
        
        # Get column names
        columns = [desc[0] for desc in cursor.description]
        
        # Convert to dictionary
        application = dict(zip(columns, row))
        
        # Convert datetime objects to ISO strings
        if application['submitted_at']:
            application['submitted_at'] = application['submitted_at'].isoformat()
        if application['created_at']:
            application['created_at'] = application['created_at'].isoformat()
        if application['updated_at']:
            application['updated_at'] = application['updated_at'].isoformat()
        
        # Convert UUID to string
        if application['id']:
            application['id'] = str(application['id'])
        
        # Generate presigned URL for CV if it exists
        if application['cv_file_path']:
            presigned_url = generate_presigned_url(application['cv_file_path'])
            application['cv_download_url'] = presigned_url
        
        cursor.close()
        conn.close()
        
        logger.info(f"Retrieved application: {application_id}")
        
        # Query string parameters for additional options
        query_params = event.get('queryStringParameters', {}) or {}
        include_cv_content = query_params.get('include_cv_content', 'false').lower() == 'true'
        
        # If CV content is requested and file exists
        if include_cv_content and application['cv_file_path']:
            try:
                response = s3.get_object(
                    Bucket=S3_BUCKET,
                    Key=application['cv_file_path']
                )
                # Note: For large files, you might want to stream this differently
                cv_content = response['Body'].read()
                application['cv_content_base64'] = cv_content.hex()  # Convert to hex for JSON serialization
                application['cv_content_size'] = len(cv_content)
            except Exception as e:
                logger.error(f"Error reading CV content: {str(e)}")
                application['cv_content_error'] = str(e)
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
            },
            'body': json.dumps(application, default=str)
        }
        
    except psycopg2.Error as db_error:
        logger.error(f"Database error: {str(db_error)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
            },
            'body': json.dumps({
                'message': 'Database error occurred',
                'error': str(db_error)
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
            },
            'body': json.dumps({
                'message': 'Internal server error',
                'error': str(e)
            })
        }