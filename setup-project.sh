#!/bin/bash
set -e

# MXCP Project Template Setup Script
# Automates the customization steps from README.md (steps 2, 3, 4)

# =============================================================================
# TEMPLATE PLACEHOLDERS REFERENCE
# =============================================================================
# This script replaces the following placeholders in template files:
#
# {{PROJECT_NAME}}           - Your project name (e.g., "uae-licenses")
#                             Used in: config.env.template, justfile.template,
#                                     mxcp-site-docker.yml.template, 
#                                     profiles-docker.yml.template,
#                                     mxcp-user-config.yml.template
#
# {{AWS_REGION}}            - AWS region (e.g., "eu-west-1")
#                             Used in: profiles-docker.yml.template
#
# {{DATA_DOWNLOAD_COMMAND}} - Command to download/prepare data
#                             Used in: justfile.template
#                             Default: python3 scripts/download_real_data.py --output data/licenses.csv
#
# {{DBT_DEPS_COMMAND}}      - dbt deps command or placeholder for API projects
#                             Used in: justfile.template
#                             Default: dbt deps
#
# {{DBT_RUN_COMMAND}}       - dbt run command with project-specific vars
#                             Used in: justfile.template
#                             Default: dbt run --vars '{"licenses_file": "data/licenses.csv"}'
#
# {{DBT_TEST_COMMAND}}      - dbt test command with project-specific vars
#                             Used in: justfile.template
#                             Default: dbt test --vars '{"licenses_file": "data/licenses.csv"}'
#
# {{MXCP_EVALS_COMMANDS}}   - MXCP evaluation test commands
#                             Used in: justfile.template
#                             Default: mxcp evals (runs all)
#
# {{API_TEST_COMMAND}}      - API test command (for API projects)
#                             Used in: justfile.template
#                             Default: python tests/test.py api (api projects)
#                                      @echo message (data projects)
# =============================================================================

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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "deployment/config.env.template" ]; then
    print_error "This script must be run from the project root directory (where deployment/ exists)"
    exit 1
fi

# Parse arguments
FORCE=false
PROJECT_NAME=""
AWS_REGION="eu-west-1"  # Default region
PROJECT_TYPE="data"     # Default project type: data, remote_data, or api

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --type)
            PROJECT_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage=true
            shift
            ;;
        *)
            # Support legacy positional arguments for backward compatibility
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            elif [ "$AWS_REGION" == "eu-west-1" ]; then
                AWS_REGION="$1"
            fi
            shift
            ;;
    esac
done

# Show usage if no project name or help requested
if [ -z "$PROJECT_NAME" ] || [ "$show_usage" == "true" ]; then
    echo -e "${BLUE}🚀 MXCP Project Template Setup${NC}"
    echo ""
    echo "Usage: $0 --name <project-name> [options]"
    echo ""
    echo "Options:"
    echo "  --name <name>        Project name (required)"
    echo "  --region <region>    AWS region (default: eu-west-1)"
    echo "  --type <type>        Project type: data, remote_data, or api (default: data)"
    echo "  --force              Overwrite existing files without prompting"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --name uae-licenses"
    echo "  $0 --name finance-demo --region us-west-2 --type remote_data"
    echo "  $0 --name vertec-poc --type api"
    echo ""
    echo "Legacy format (still supported):"
    echo "  $0 uae-licenses"
    echo "  $0 finance-demo us-west-2"
    echo ""
    exit 1
fi

# Validate project name (alphanumeric and hyphens only)
if ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    print_error "Invalid project name. Use only letters, numbers, and hyphens."
    exit 1
fi

# Set default region if not provided
AWS_REGION="${AWS_REGION:-eu-west-1}"

# Validate AWS region format
if ! [[ "$AWS_REGION" =~ ^[a-z]{2}-[a-z]+-[0-9]+$ ]]; then
    print_warning "AWS region format looks incorrect: $AWS_REGION"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Validate project type
if [[ ! "$PROJECT_TYPE" =~ ^(data|remote_data|api)$ ]]; then
    print_error "Invalid project type: $PROJECT_TYPE"
    print_error "Must be one of: data, remote_data, api"
    exit 1
fi

print_step "Setting up MXCP project: $PROJECT_NAME"
echo "AWS Region: $AWS_REGION"
echo "Project Type: $PROJECT_TYPE"
echo ""

# Function to safely copy file with overwrite check
safe_copy() {
    local source="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -f "$dest" ] && [ "$FORCE" != "true" ]; then
        print_warning "$dest already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Skipped $desc"
            return 1
        fi
    fi
    
    cp "$source" "$dest"
    return 0
}

# Step 2: Customize Configuration
print_step "Step 2: Customizing deployment configuration..."

if safe_copy "deployment/config.env.template" "deployment/config.env" "deployment configuration"; then
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" deployment/config.env
    print_success "Created deployment/config.env with project name: $PROJECT_NAME"
fi

# Step 3: Setup Task Runner
print_step "Step 3: Setting up task runner..."

if safe_copy "justfile.template" "justfile" "task runner"; then
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" justfile
    
    # Replace placeholders based on project type
    case "$PROJECT_TYPE" in
        data)
            # Local data files (e.g., CSV in data/ directory)
            sed -i "s|{{DATA_DOWNLOAD_COMMAND}}|@echo '📁 Using local data files from data/ directory'|g" justfile
            sed -i "s|{{DBT_DEPS_COMMAND}}|dbt deps|g" justfile
            sed -i "s|{{DBT_RUN_COMMAND}}|dbt run --vars '{\"licenses_file\": \"data/licenses.csv\"}'|g" justfile
            sed -i "s|{{DBT_TEST_COMMAND}}|dbt test --vars '{\"licenses_file\": \"data/licenses.csv\"}'|g" justfile
            sed -i "s|{{API_TEST_COMMAND}}|@echo '📊 Data project - no API tests needed'|g" justfile
            ;;
        remote_data)
            # Remote data download (e.g., from S3)
            sed -i "s|{{DATA_DOWNLOAD_COMMAND}}|python3 scripts/download_real_data.py --output data/licenses.csv|g" justfile
            sed -i "s|{{DBT_DEPS_COMMAND}}|dbt deps|g" justfile
            sed -i "s|{{DBT_RUN_COMMAND}}|dbt run --vars '{\"licenses_file\": \"data/licenses.csv\"}'|g" justfile
            sed -i "s|{{DBT_TEST_COMMAND}}|dbt test --vars '{\"licenses_file\": \"data/licenses.csv\"}'|g" justfile
            sed -i "s|{{API_TEST_COMMAND}}|@echo '📊 Data project - no API tests needed'|g" justfile
            ;;
        api)
            # API-based project (no data download or dbt)
            sed -i "s|{{DATA_DOWNLOAD_COMMAND}}|@echo '🔌 API-based project - no data download needed'|g" justfile
            sed -i "s|{{DBT_DEPS_COMMAND}}|@echo '🔌 API-based project - no dbt dependencies'|g" justfile
            sed -i "s|{{DBT_RUN_COMMAND}}|@echo '🔌 API-based project - no dbt models'|g" justfile
            sed -i "s|{{DBT_TEST_COMMAND}}|@echo '🔌 API-based project - no dbt tests'|g" justfile
            sed -i "s|{{API_TEST_COMMAND}}|python tests/test.py api|g" justfile
            ;;
    esac
    
    # Simple eval command that runs all evals
    sed -i "s|{{MXCP_EVALS_COMMANDS}}|mxcp evals|g" justfile
    
    print_success "Created justfile with $PROJECT_TYPE project defaults"
fi

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
if safe_copy "deployment/mxcp-site-docker.yml.template" "deployment/mxcp-site-docker.yml" "MXCP site configuration"; then
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" deployment/mxcp-site-docker.yml
    print_success "Created deployment/mxcp-site-docker.yml"
fi

# Update dbt profiles
if safe_copy "deployment/profiles-docker.yml.template" "deployment/profiles-docker.yml" "dbt profiles"; then
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{AWS_REGION}}/$AWS_REGION/g" deployment/profiles-docker.yml
    print_success "Created deployment/profiles-docker.yml"
    
    # If dbt_project.yml exists, update the profile name to match
    if [ -f "dbt_project.yml" ]; then
        print_step "Found dbt_project.yml - updating profile name to match..."
        # Create the new profile name
        NEW_PROFILE="${PROJECT_NAME}-mxcp"
        # Update the profile line in dbt_project.yml
        if sed -i "s/^profile:.*/profile: $NEW_PROFILE/" dbt_project.yml; then
            print_success "Updated dbt_project.yml profile to: $NEW_PROFILE"
        else
            print_warning "Could not update dbt_project.yml - please manually set profile: $NEW_PROFILE"
        fi
    fi
fi

# Copy MXCP user configuration
if safe_copy "deployment/mxcp-user-config.yml.template" "deployment/mxcp-user-config.yml" "MXCP user configuration"; then
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" deployment/mxcp-user-config.yml
    print_success "Created deployment/mxcp-user-config.yml"
    print_warning "Remember to set environment variables for API keys in this file"
fi

# Step 5: Create Environment Documentation
print_step "Step 5: Creating environment documentation..."

# Note: Environment documentation is now self-contained in Docker labels
# Run: docker inspect <image> | grep 'env\.' to see all requirements

# Process .squirro templates
if [ -d ".squirro" ]; then
    print_step "Processing .squirro templates..."
    
    # Process setup-for-squirro.sh.template
    if [ -f ".squirro/setup-for-squirro.sh.template" ]; then
        safe_copy ".squirro/setup-for-squirro.sh.template" ".squirro/setup-for-squirro.sh"
        sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" .squirro/setup-for-squirro.sh
        chmod +x .squirro/setup-for-squirro.sh
        print_success "Created .squirro/setup-for-squirro.sh"
    fi
    
    # Process workflow template
    if [ -f ".squirro/workflows/build-and-push-to-ecr.yml.template" ]; then
        safe_copy ".squirro/workflows/build-and-push-to-ecr.yml.template" ".squirro/workflows/build-and-push-to-ecr.yml"
        sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" .squirro/workflows/build-and-push-to-ecr.yml
        print_success "Created .squirro/workflows/build-and-push-to-ecr.yml"
    fi
fi

# Step 6: Handle .gitignore
print_step "Step 6: Updating .gitignore..."

# Check if .gitignore exists
if [ -f ".gitignore" ]; then
    print_info "Found existing .gitignore - updating to ensure deployment files are tracked..."
    
    # Check if these files are currently ignored and remove those entries
    for file in "deployment/config.env" "deployment/mxcp-site-docker.yml" "deployment/profiles-docker.yml" "deployment/mxcp-user-config.yml" "justfile"; do
        # Remove exact matches
        sed -i "/^$(echo $file | sed 's/\//\\\//g')$/d" .gitignore
        # Remove with leading slash
        sed -i "/^\/$(echo $file | sed 's/\//\\\//g')$/d" .gitignore
    done
    
    # Add a note about deployment files
    if ! grep -q "# MXCP Deployment files" .gitignore; then
        echo "" >> .gitignore
        echo "# MXCP Deployment files - NOT ignored (required for CI/CD)" >> .gitignore
        echo "# deployment/config.env" >> .gitignore
        echo "# deployment/mxcp-site-docker.yml" >> .gitignore
        echo "# deployment/profiles-docker.yml" >> .gitignore
        echo "# deployment/mxcp-user-config.yml" >> .gitignore
        echo "# justfile" >> .gitignore
    fi
    
    print_success "Updated .gitignore - deployment files will be tracked in git"
else
    print_warning "No .gitignore found"
    print_info "Creating basic .gitignore with deployment files NOT ignored..."
    
    cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.*.local

# MXCP Deployment files - NOT ignored (required for CI/CD)
# deployment/config.env
# deployment/mxcp-site-docker.yml
# deployment/profiles-docker.yml
# deployment/mxcp-user-config.yml
# justfile

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/

# Data files
data/
*.csv
*.json
*.parquet

# dbt
target/
dbt_packages/
logs/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Testing
.pytest_cache/
.coverage
htmlcov/

# Temporary files
*.tmp
*.bak
*.log

# AWS
.aws/
EOF
    
    print_success "Created .gitignore with basic patterns"
fi


# Summary
echo ""
print_success "🎉 Project setup complete!"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Customize your GitHub workflow!${NC}"
echo "   Edit .github/workflows/deploy.yml and add your project's secrets to the env: block"
echo "   Example:"
echo "     env:"
echo "       OPENAI_API_KEY: \${{ secrets.OPENAI_API_KEY || '' }}"
echo "       YOUR_API_KEY: \${{ secrets.YOUR_API_KEY || '' }}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Run: mxcp init --bootstrap"
echo "2. ${YELLOW}Customize .github/workflows/deploy.yml with your project's secrets${NC}"
echo "3. Choose your data strategy (see README)"
echo "4. Review and commit the generated files to git"
echo "5. Set GitHub repository secrets (check .github/workflows/deploy.yml env: block)"
echo "6. Push to trigger deployment: git push origin main"
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
echo -e "${BLUE}Type:    ${GREEN}$PROJECT_TYPE${NC}"
echo ""

# Step 7: Clean up template files
print_step "Step 7: Cleaning up template files..."

# Remove all .template files that have been processed
template_files=(
    "justfile.template"
    "deployment/config.env.template"
    "deployment/mxcp-site-docker.yml.template"
    "deployment/profiles-docker.yml.template"
    "deployment/mxcp-user-config.yml.template"
    ".squirro/setup-for-squirro.sh.template"
    ".squirro/workflows/build-and-push-to-ecr.yml.template"
)

for template in "${template_files[@]}"; do
    if [ -f "$template" ]; then
        rm -f "$template"
        print_info "Removed $template"
    fi
done

# Remove setup script itself
rm -f "$0"
print_info "Removed setup script"

print_success "Template files cleaned up"
