#!/bin/bash
# LocalStack Terraform Demo Setup Script

set -e

echo "🚀 Setting up Terraform + LocalStack Demo..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script is designed for macOS${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check Docker
if ! command_exists docker; then
    echo -e "${RED}❌ Docker not found. Installing Docker Desktop...${NC}"
    brew install --cask docker
    echo -e "${YELLOW}⚠️  Please start Docker Desktop and run this script again${NC}"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Check Python 3
if ! command_exists python3; then
    echo -e "${RED}❌ Python 3 not found. Installing...${NC}"
    brew install python
fi

echo -e "${GREEN}✅ Python 3 found${NC}"

# Check Terraform
if ! command_exists terraform; then
    echo -e "${YELLOW}📦 Installing Terraform...${NC}"
    brew install terraform
fi

echo -e "${GREEN}✅ Terraform installed: $(terraform version -json | jq -r '.terraform_version')${NC}"

# Install LocalStack
echo -e "${YELLOW}📦 Installing LocalStack...${NC}"
pip3 install --user localstack terraform-local

# Add to PATH if not already there
if ! command_exists localstack; then
    echo -e "${YELLOW}⚠️  Adding LocalStack to PATH...${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    export PATH="$HOME/.local/bin:$PATH"
fi

echo -e "${GREEN}✅ LocalStack installed${NC}"

# Start LocalStack
echo -e "${YELLOW}🐳 Starting LocalStack...${NC}"
localstack start -d

# Wait for LocalStack to be ready
echo -e "${YELLOW}⏳ Waiting for LocalStack to be ready...${NC}"
sleep 10

# Check LocalStack health
if curl -s http://localhost:4566/health > /dev/null; then
    echo -e "${GREEN}✅ LocalStack is running!${NC}"
    echo -e "${GREEN}🌐 LocalStack Web UI: http://localhost:4566${NC}"
else
    echo -e "${RED}❌ LocalStack failed to start${NC}"
    exit 1
fi

# Initialize Terraform
echo -e "${YELLOW}⚙️  Initializing Terraform...${NC}"
tflocal init

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${GREEN}1. Review the generated Terraform files${NC}"
echo -e "${GREEN}2. Run: ${YELLOW}tflocal plan${NC}"  
echo -e "${GREEN}3. Run: ${YELLOW}tflocal apply${NC}"
echo -e "${GREEN}4. Test with the commands from terraform output${NC}"

echo -e "\n${GREEN}📚 Useful commands:${NC}"
echo -e "${YELLOW}tflocal plan${NC}     - Preview changes"
echo -e "${YELLOW}tflocal apply${NC}    - Apply changes" 
echo -e "${YELLOW}tflocal destroy${NC}  - Destroy infrastructure"
echo -e "${YELLOW}localstack logs${NC}  - View LocalStack logs"
echo -e "${YELLOW}localstack stop${NC}  - Stop LocalStack"

echo -e "\n${GREEN}🧪 Quick test:${NC}"
echo -e "${YELLOW}awslocal s3 ls${NC}   - List S3 buckets (after terraform apply)"