#!/bin/bash

# Create Lambda deployment packages with dependencies
# This script creates zip files with Python code and dependencies

set -e

echo "Creating Lambda deployment packages..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Function to create Lambda package
create_lambda_package() {
    local function_name=$1
    local python_file=$2
    
    echo "Creating package for $function_name..."
    
    # Create function directory
    local func_dir="$TEMP_DIR/$function_name"
    mkdir -p "$func_dir"
    
    # Copy Python file
    cp "backend/$python_file" "$func_dir/lambda_function.py"
    
    # Install dependencies
    pip install -r backend/requirements.txt -t "$func_dir" --no-deps --platform manylinux2014_x86_64 --implementation cp --python-version 3.9 --only-binary=:all:
    
    # Create zip file
    cd "$func_dir"
    zip -r "../../$function_name.zip" .
    cd - > /dev/null
    
    echo "Created $function_name.zip"
}

# Create packages for each Lambda function
create_lambda_package "submit_cv" "submit_cv.py"
create_lambda_package "list_applications" "list_applications.py"
create_lambda_package "get_application" "get_application.py"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "Lambda packages created successfully!"
echo "Files created:"
ls -la *.zip