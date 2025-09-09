#!/bin/bash
set -e

# MXCP Project Template Setup Script
# Automates the customization steps from README.md (steps 2, 3, 4)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "deployment/config.env.template" ]; then
    print_error "This script must be run from the project root directory (where deployment/ exists)"
    exit 1
fi

# Get project name
if [ -z "$1" ]; then
    echo -e "${BLUE}🚀 MXCP Project Template Setup${NC}"
    echo ""
    echo "Usage: $0 PROJECT_NAME [AWS_REGION]"
    echo ""
    echo "Examples:"
    echo "  $0 finance-demo"
    echo "  $0 uae-licenses us-west-2"
    echo ""
    exit 1
fi

PROJECT_NAME="$1"
AWS_REGION="${2:-eu-west-1}"  # Default to RAW Labs region

print_step "Setting up MXCP project: $PROJECT_NAME"
echo "AWS Region: $AWS_REGION"
echo ""

# Step 2: Customize Configuration
print_step "Step 2: Customizing deployment configuration..."

cp deployment/config.env.template deployment/config.env
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" deployment/config.env

print_success "Created deployment/config.env with project name: $PROJECT_NAME"

# Step 3: Setup Task Runner
print_step "Step 3: Setting up task runner..."

cp justfile.template justfile
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" justfile

print_success "Created justfile with project name: $PROJECT_NAME"

# Check if just is installed
if ! command -v just &> /dev/null; then
    print_warning "just task runner not found. Installing..."
    if curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin; then
        print_success "Installed just task runner to ~/.local/bin"
        echo "Add ~/.local/bin to your PATH if not already done:"
        echo "  export PATH=~/.local/bin:\$PATH"
    else
        print_warning "Failed to install just. You can install it manually later."
    fi
else
    print_success "just task runner already installed"
fi

# Step 4: Customize Docker Configuration
print_step "Step 4: Customizing Docker configuration..."

# Update MXCP configuration
cp deployment/mxcp-site-docker.yml.template deployment/mxcp-site-docker.yml
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" deployment/mxcp-site-docker.yml

print_success "Created deployment/mxcp-site-docker.yml"

# Update dbt profiles
cp deployment/profiles-docker.yml.template deployment/profiles-docker.yml
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{AWS_REGION}}/$AWS_REGION/g" deployment/profiles-docker.yml

print_success "Created deployment/profiles-docker.yml"

# Copy MXCP user configuration
cp deployment/mxcp-user-config.yml.template deployment/mxcp-user-config.yml

print_success "Created deployment/mxcp-user-config.yml"

# Summary
echo ""
print_success "🎉 Project setup complete!"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Run: mxcp init --bootstrap (Step 5 from README)"
echo "2. Choose your data strategy (Step 6 from README)"
echo "3. Set GitHub repository secrets for deployment"
echo "4. Push to trigger deployment: git push origin main"
echo ""
echo -e "${BLUE}Files created:${NC}"
echo "- deployment/config.env"
echo "- justfile"
echo "- deployment/mxcp-site-docker.yml"
echo "- deployment/profiles-docker.yml"
echo "- deployment/mxcp-user-config.yml"
echo ""
echo -e "${BLUE}Project: ${GREEN}$PROJECT_NAME${NC}"
echo -e "${BLUE}Region:  ${GREEN}$AWS_REGION${NC}"
