# S3 Bucket for application storage
resource "aws_s3_bucket" "app_storage" {
  bucket = "terraform-demo-bucket-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for user data
resource "aws_dynamodb_table" "user_data" {
  name           = "user-data-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Name        = "UserDataTable"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "terraform-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "terraform-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.user_data.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.app_storage.arn}/*"
      }
    ]
  })
}

# Archive Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda.zip"
  source {
    content = <<EOF
import json
import boto3
import os

def handler(event, context):
    """
    Simple Lambda function that demonstrates:
    - DynamoDB interaction
    - S3 interaction 
    - Environment variables
    """

    # Initialize AWS clients (will use LocalStack endpoints)
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.client('s3')

    # Get table and bucket names from environment
    table_name = os.environ.get('DYNAMODB_TABLE', 'user-data-table')
    bucket_name = os.environ.get('S3_BUCKET')

    try:
        # Test DynamoDB connection
        table = dynamodb.Table(table_name)

        # Test S3 connection
        s3_response = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1)

        response_body = {
            'message': 'Hello from Terraform + LocalStack!',
            'environment': os.environ.get('ENVIRONMENT', 'development'),
            'dynamodb_table': table_name,
            's3_bucket': bucket_name,
            'lambda_version': context.function_version if context else 'local',
            'status': 'success'
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_body, indent=2)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Error occurred',
                'error': str(e),
                'status': 'error'
            })
        }
EOF
    filename = "lambda_function.py"
  }
}

# Lambda Function
resource "aws_lambda_function" "demo_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "terraform-demo-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.handler"
  runtime         = "python3.9"
  timeout         = 30

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT     = var.environment
      DYNAMODB_TABLE  = aws_dynamodb_table.user_data.name
      S3_BUCKET       = aws_s3_bucket.app_storage.bucket
    }
  }

  tags = {
    Name        = "DemoLambdaFunction"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Sample data in DynamoDB
resource "aws_dynamodb_table_item" "sample_user_1" {
  table_name = aws_dynamodb_table.user_data.name
  hash_key   = aws_dynamodb_table.user_data.hash_key

  item = <<ITEM
{
  "user_id": {"S": "user-001"},
  "name": {"S": "John Doe"},
  "email": {"S": "john.doe@example.com"},
  "created_at": {"S": "2024-01-15T10:30:00Z"},
  "status": {"S": "active"}
}
ITEM
}

resource "aws_dynamodb_table_item" "sample_user_2" {
  table_name = aws_dynamodb_table.user_data.name
  hash_key   = aws_dynamodb_table.user_data.hash_key

  item = <<ITEM
{
  "user_id": {"S": "user-002"},
  "name": {"S": "Swadha Khatod"},
  "email": {"S": "Swadha@example.com"},
  "created_at": {"S": "2024-01-16T14:22:00Z"},
  "status": {"S": "active"}
}
ITEM
}

# S3 Object with sample data
resource "aws_s3_object" "sample_config" {
  bucket = aws_s3_bucket.app_storage.bucket
  key    = "config/application.json"

  content = jsonencode({
    application = {
      name        = "Terraform Demo App"
      version     = "1.0.0"
      environment = var.environment
    }
    database = {
      table = aws_dynamodb_table.user_data.name
    }
    storage = {
      bucket = aws_s3_bucket.app_storage.bucket
    }
    lambda = {
      function = aws_lambda_function.demo_function.function_name
    }
  })

  content_type = "application/json"
}

resource "aws_s3_object" "readme" {
  bucket = aws_s3_bucket.app_storage.bucket
  key    = "README.md"

  content = <<EOF
# Terraform Demo Infrastructure

This infrastructure was created by Terraform using LocalStack.

## Resources Created:
- S3 Bucket: ${aws_s3_bucket.app_storage.bucket}
- DynamoDB Table: ${aws_dynamodb_table.user_data.name}
- Lambda Function: ${aws_lambda_function.demo_function.function_name}

## Environment: ${var.environment}
## Created: ${timestamp()}

## Testing:
1. Test Lambda: `awslocal lambda invoke --function-name ${aws_lambda_function.demo_function.function_name} response.json`
2. List S3 objects: `awslocal s3 ls s3://${aws_s3_bucket.app_storage.bucket}/`
3. Scan DynamoDB: `awslocal dynamodb scan --table-name ${aws_dynamodb_table.user_data.name}`
EOF

  content_type = "text/markdown"
}