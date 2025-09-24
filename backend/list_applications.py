"""
DevOps Job Portal - List Applications Lambda Function

This Lambda function handles retrieving job applications with:
- Pagination support
- Filtering by email, experience, and date range
- Proper error handling and logging
- Performance optimized database queries

Author: DevOps Job Portal Team
Date: September 2025
"""

import json
import os
import psycopg2
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Database connection parameters from environment variables
DB_HOST = os.environ['DB_HOST']
DB_PORT = os.environ['DB_PORT']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']

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

def lambda_handler(event, context):
    """
    Main Lambda handler for listing applications with optional filtering and pagination.
    
    Args:
        event (dict): Lambda event object containing query parameters
        context (object): Lambda context object
        
    Returns:
        dict: HTTP response object with applications list and metadata
    """
    try:
        logger.info("Fetching applications list")
        
        # Get query parameters
        query_params = event.get('queryStringParameters', {}) or {}
        page = int(query_params.get('page', 1))
        limit = int(query_params.get('limit', 50))
        offset = (page - 1) * limit
        
        # Optional filters
        email_filter = query_params.get('email')
        experience_filter = query_params.get('experience')
        date_from = query_params.get('date_from')
        date_to = query_params.get('date_to')
        
        # Build query
        base_query = """
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
                created_at
            FROM applications
        """
        
        # Build WHERE clause
        where_conditions = []
        query_params_list = []
        
        if email_filter:
            where_conditions.append("email ILIKE %s")
            query_params_list.append(f"%{email_filter}%")
        
        if experience_filter:
            where_conditions.append("experience = %s")
            query_params_list.append(experience_filter)
        
        if date_from:
            where_conditions.append("submitted_at >= %s")
            query_params_list.append(date_from)
        
        if date_to:
            where_conditions.append("submitted_at <= %s")
            query_params_list.append(date_to)
        
        # Add WHERE clause if there are conditions
        if where_conditions:
            base_query += " WHERE " + " AND ".join(where_conditions)
        
        # Add ordering and pagination
        base_query += " ORDER BY submitted_at DESC LIMIT %s OFFSET %s"
        query_params_list.extend([limit, offset])
        
        # Execute query
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(base_query, query_params_list)
        rows = cursor.fetchall()
        
        # Get column names
        columns = [desc[0] for desc in cursor.description]
        
        # Convert to dictionaries
        applications = []
        for row in rows:
            app_dict = dict(zip(columns, row))
            
            # Convert datetime objects to ISO strings
            if app_dict['submitted_at']:
                app_dict['submitted_at'] = app_dict['submitted_at'].isoformat()
            if app_dict['created_at']:
                app_dict['created_at'] = app_dict['created_at'].isoformat()
            
            # Convert UUID to string
            if app_dict['id']:
                app_dict['id'] = str(app_dict['id'])
            
            # Truncate cover letter for list view
            if app_dict['cover_letter'] and len(app_dict['cover_letter']) > 200:
                app_dict['cover_letter_preview'] = app_dict['cover_letter'][:200] + "..."
            else:
                app_dict['cover_letter_preview'] = app_dict['cover_letter']
            
            applications.append(app_dict)
        
        # Get total count for pagination
        count_query = "SELECT COUNT(*) FROM applications"
        if where_conditions:
            count_query += " WHERE " + " AND ".join(where_conditions)
        
        cursor.execute(count_query, query_params_list[:-2])  # Exclude LIMIT and OFFSET params
        total_count = cursor.fetchone()[0]
        
        cursor.close()
        conn.close()
        
        logger.info(f"Retrieved {len(applications)} applications")
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
            },
            'body': json.dumps({
                'applications': applications,
                'pagination': {
                    'current_page': page,
                    'per_page': limit,
                    'total_count': total_count,
                    'total_pages': (total_count + limit - 1) // limit,
                    'has_next': offset + len(applications) < total_count,
                    'has_prev': page > 1
                },
                'filters': {
                    'email': email_filter,
                    'experience': experience_filter,
                    'date_from': date_from,
                    'date_to': date_to
                }
            }, default=str)
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