#!/usr/bin/env python3
"""
Production Database Initialization Script
Initializes the PostgreSQL database with required tables for the DevOps Job Portal
"""

import psycopg2
import sys
import json
import subprocess

def get_terraform_output(output_name):
    """Get output value from Terraform"""
    try:
        result = subprocess.run(
            ['terraform', 'output', '-json', output_name], 
            cwd='../terraform',
            capture_output=True, 
            text=True, 
            check=True
        )
        return json.loads(result.stdout)['value']
    except subprocess.CalledProcessError as e:
        print(f"Error getting Terraform output: {e}")
        sys.exit(1)

def initialize_database():
    """Initialize the production database with required tables"""
    
    # Get database connection details from Terraform
    print("Getting database connection details from Terraform...")
    db_host = get_terraform_output('rds_endpoint')
    db_port = get_terraform_output('rds_port')
    
    # Database credentials (these should match your terraform.tfvars)
    db_name = 'jobportal'
    db_user = 'dbadmin'
    db_password = 'ChangeMe123!'  # Same as in terraform.tfvars.prod
    
    print(f"Connecting to production database at {db_host}:{db_port}")
    
    try:
        # Connect to the database
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password
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
        
        print("✅ Applications table created successfully!")
        
        # Verify the table was created
        cursor.execute("SELECT COUNT(*) FROM applications;")
        count = cursor.fetchone()[0]
        print(f"✅ Table verified. Current applications count: {count}")
        
        # Create an index for better performance
        cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_applications_email 
        ON applications(email);
        """)
        
        cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_applications_submitted_at 
        ON applications(submitted_at);
        """)
        
        conn.commit()
        print("✅ Database indexes created successfully!")
        
        cursor.close()
        conn.close()
        
        print("🎉 Production database initialization completed successfully!")
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    initialize_database()