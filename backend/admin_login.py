import json
import os
import hashlib
import jwt
import datetime
import logging
import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS client
secrets_client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    """
    Admin login handler
    """
    try:
        # Enable CORS
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS',
            'Content-Type': 'application/json'
        }
        
        # Handle preflight OPTIONS request
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'OK'})
            }
        
        # Parse request body
        if 'body' not in event or not event['body']:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'success': False,
                    'message': 'Missing request body'
                })
            }
        
        try:
            body = json.loads(event['body'])
        except json.JSONDecodeError:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'success': False,
                    'message': 'Invalid JSON format'
                })
            }
        
        # Get credentials from request
        username = body.get('username', '').strip()
        password = body.get('password', '').strip()
        
        if not username or not password:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'success': False,
                    'message': 'Username and password are required'
                })
            }
        
        # Get admin credentials from Secrets Manager
        admin_creds = get_admin_credentials()
        if not admin_creds:
            logger.error("Failed to retrieve admin credentials")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({
                    'success': False,
                    'message': 'Authentication service unavailable'
                })
            }
        
        # Verify credentials
        if not verify_credentials(username, password, admin_creds):
            logger.warning(f"Failed login attempt for username: {username}")
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({
                    'success': False,
                    'message': 'Invalid username or password'
                })
            }
        
        # Generate JWT token
        token = generate_jwt_token(username, admin_creds['jwt_secret'])
        
        logger.info(f"Successful admin login for username: {username}")
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'success': True,
                'message': 'Login successful',
                'token': token,
                'expires_in': 86400  # 24 hours in seconds
            })
        }
        
    except Exception as e:
        logger.error(f"Admin login error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'success': False,
                'message': 'Internal server error'
            })
        }

def get_admin_credentials():
    """
    Get admin credentials from AWS Secrets Manager
    """
    try:
        secret_name = os.environ.get('ADMIN_CREDENTIALS_SECRET')
        if not secret_name:
            logger.error("ADMIN_CREDENTIALS_SECRET environment variable not set")
            return None
            
        response = secrets_client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
        
    except ClientError as e:
        logger.error(f"Failed to retrieve admin credentials: {str(e)}")
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in admin credentials secret: {str(e)}")
        return None

def verify_credentials(username, password, admin_creds):
    """
    Verify admin credentials against stored values
    """
    # Check username
    if username != admin_creds.get('username'):
        return False
    
    # Check password hash
    password_hash = hashlib.sha256(password.encode()).hexdigest()
    return password_hash == admin_creds.get('password_hash')

def generate_jwt_token(username, jwt_secret):
    """
    Generate JWT token for authenticated admin
    """
    payload = {
        'username': username,
        'role': 'admin',
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }
    
    token = jwt.encode(payload, jwt_secret, algorithm='HS256')
    return token

def verify_jwt_token(token, jwt_secret):
    """
    Verify JWT token (for future use in protected endpoints)
    """
    try:
        payload = jwt.decode(token, jwt_secret, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None