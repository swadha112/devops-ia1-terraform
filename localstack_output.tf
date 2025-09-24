# S3 Bucket Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.app_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_storage.arn
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.user_data.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.user_data.arn
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.demo_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.demo_function.arn
}

# Quick Test Commands
output "test_commands" {
  description = "Commands to test the infrastructure"
  value = <<EOF

🧪 Test Commands:
================

# Test Lambda Function:
awslocal lambda invoke --function-name ${aws_lambda_function.demo_function.function_name} response.json && cat response.json

# List S3 Objects:
awslocal s3 ls s3://${aws_s3_bucket.app_storage.bucket}/

# Read S3 Object:
awslocal s3 cp s3://${aws_s3_bucket.app_storage.bucket}/README.md - 

# Scan DynamoDB Table:
awslocal dynamodb scan --table-name ${aws_dynamodb_table.user_data.name}

# Get specific user from DynamoDB:
awslocal dynamodb get-item --table-name ${aws_dynamodb_table.user_data.name} --key '{"user_id":{"S":"user-001"}}'

# LocalStack Web UI:
open http://localhost:4566/health

EOF
}