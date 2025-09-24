import json
import psycopg2
import os

def lambda_handler(event, context):
    """
    Lambda function to initialize the production database
    This runs within the VPC so it can access the private RDS instance
    """
    
    # Get database connection details from environment variables
    db_host = os.environ.get('DB_HOST')
    db_port = int(os.environ.get('DB_PORT', 5432))
    db_name = os.environ.get('DB_NAME')
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')
    
    print(f"Initializing database at {db_host}:{db_port}")
    
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password,
            connect_timeout=30
        )
        
        cursor = conn.cursor()
        
        print("Creating applications table...")
        
        # Create applications table
        create_table_query = """
        CREATE TABLE IF NOT EXISTS applications (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL,
            experience VARCHAR(50) NOT NULL,
            cv_key VARCHAR(500) NOT NULL,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        cursor.execute(create_table_query)
        conn.commit()
        
        print("Applications table created successfully!")
        
        # Verify the table was created
        cursor.execute("SELECT COUNT(*) FROM applications;")
        count = cursor.fetchone()[0]
        print(f"Table verified. Current applications count: {count}")
        
        # Create indexes for better performance
        cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_applications_email 
        ON applications(email);
        """)
        
        cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_applications_submitted_at 
        ON applications(submitted_at);
        """)
        
        conn.commit()
        print("Database indexes created successfully!")
        
        cursor.close()
        conn.close()
        
        result = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Database initialized successfully!',
                'applications_count': count
            })
        }
        
        print("Database initialization completed successfully!")
        return result
        
    except psycopg2.Error as e:
        error_msg = f"Database error: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg
            })
        }
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg
            })
        }