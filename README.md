Terraform DevOps Pipeline - Alternative Infrastructure as Code Implementation

Assignment: DevOps Alternative Tools Exploration  
Tool: Terraform + LocalStack (Infrastructure as Code)  

**Project Overview**

This project demonstrates **Terraform as an alternative DevOps tool** for Infrastructure as Code (IaC), replacing traditional manual cloud management approaches. Using LocalStack for local AWS simulation, this implementation showcases a complete DevOps pipeline.

Architecture Overview

The pipeline implements a modern Infrastructure as Code workflow using Terraform to manage AWS-like services locally through LocalStack.

<img width="876" height="700" alt="image" src="https://github.com/user-attachments/assets/83bf1ae4-9e1a-4460-994d-dc818eb72c8a" />

Pipeline Workflow

1. **Developer** writes Terraform configuration files
2. **Terraform** plans and applies infrastructure changes
3. **LocalStack** simulates AWS services locally (S3, DynamoDB, Lambda)
4. **Infrastructure** gets created and managed as code
5. **Testing** validates deployed resources
6. **Documentation** auto-generated from infrastructure

Core Configuration Files

main.tf	: Infrastructure Definition	Defines S3 buckets, DynamoDB tables, Lambda functions, and IAM roles

providers.tf :	Provider Configuration	Configures AWS provider to use LocalStack endpoints

variables.tf :	Input Variables	Defines configurable parameters for the infrastructure

outputs.tf :	Output Values	Exposes important resource information after deployment

.gitignore :	Security & Cleanup	Prevents sensitive files from being committed to Git


Resources Created

- **S3 Bucket** - Object storage with versioning and security policies
- **DynamoDB Table** - NoSQL database with sample user data
- **Lambda Function** - Serverless compute with IAM roles and policies
- **IAM Roles & Policies** - Security and access management
- **Sample Data** - Pre-populated test data for demonstration

Quick Setup

Prerequisites

```bash
# Install required tools on Mac
brew install terraform 
```

One-Command Setup

```bash
chmod +x scripts/setup.sh && ./scripts/setup.sh
```

Manual Setup Steps

```bash
# 1. Install LocalStack
pip3 install localstack terraform-local

# 2. Start LocalStack
localstack start

# 3. Initialize and apply Terraform
tflocal apply

```

Basic Infrastructure Testing

```bash
# Test S3 bucket
aws --endpoint-url=http://localhost:4566 s3 ls s3://terraform-demo-bucket-*/

# Test DynamoDB table  
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name user-data-table

# Test Lambda function
aws --endpoint-url=http://localhost:4566 lambda invoke --function-name terraform-demo-function response.json
```

Browser Testing (No CLI needed)

```bash
# Open LocalStack web interface
open http://localhost:4566

# View S3 objects directly
open http://localhost:4566/terraform-demo-bucket-*/README.md
```
