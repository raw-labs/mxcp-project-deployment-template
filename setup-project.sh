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
#                                     ENVIRONMENT.md.template
#
# {{AWS_REGION}}            - AWS region (e.g., "eu-west-1")
#                             Used in: profiles-docker.yml.template
#
# {{DATA_DOWNLOAD_COMMAND}} - Command to download/prepare data
#                             Used in: justfile.template
#                             Default: python3 scripts/download_real_data.py --output data/licenses.csv
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
#                             Default: Multiple mxcp evals commands
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

# Check if we're in the right directory
if [ ! -f "deployment/config.env.template" ]; then
    print_error "This script must be run from the project root directory (where deployment/ exists)"
    exit 1
fi

# Parse arguments
FORCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            elif [ -z "$AWS_REGION" ]; then
                AWS_REGION="$1"
            fi
            shift
            ;;
    esac
done

# Show usage if no project name
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${BLUE}🚀 MXCP Project Template Setup${NC}"
    echo ""
    echo "Usage: $0 [--force] PROJECT_NAME [AWS_REGION]"
    echo ""
    echo "Options:"
    echo "  --force    Overwrite existing files without prompting"
    echo ""
    echo "Examples:"
    echo "  $0 finance-demo"
    echo "  $0 uae-licenses us-west-2"
    echo "  $0 --force my-project eu-central-1"
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

print_step "Setting up MXCP project: $PROJECT_NAME"
echo "AWS Region: $AWS_REGION"
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
    
    # Replace generic placeholders with UAE-specific commands (default example)
    # Projects can customize these commands for their specific data sources
    sed -i "s|{{DATA_DOWNLOAD_COMMAND}}|python3 scripts/download_real_data.py --output data/licenses.csv|g" justfile
    sed -i "s|{{DBT_RUN_COMMAND}}|dbt run --vars '{\"licenses_file\": \"data/licenses.csv\"}'|g" justfile
    sed -i "s|{{DBT_TEST_COMMAND}}|dbt test --vars '{\"licenses_file\": \"data/licenses.csv\"}'|g" justfile
    # Replace eval commands placeholder with multiple eval calls
    sed -i "s|{{MXCP_EVALS_COMMANDS}}|mxcp evals licenses_basic|g" justfile
    sed -i "/mxcp evals licenses_basic/a\\    mxcp evals search_functionality\\n    mxcp evals aggregation_analysis\\n    mxcp evals geographic_analysis\\n    mxcp evals timeseries_analysis\\n    mxcp evals edge_cases" justfile
    
    print_success "Created justfile with project-specific commands"
    print_warning "Note: Using UAE project commands as defaults. Customize for your data sources if needed."
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
    print_success "Created deployment/mxcp-user-config.yml"
    print_warning "Remember to set environment variables for API keys in this file"
fi

# Step 5: Create Environment Documentation
print_step "Step 5: Creating environment documentation..."

# Create main environment guide
if safe_copy "ENVIRONMENT.md.template" "ENVIRONMENT.md" "environment documentation"; then
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" ENVIRONMENT.md
    print_success "Created ENVIRONMENT.md with project-specific variables"
fi


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
echo "- ENVIRONMENT.md"
echo ""
echo -e "${BLUE}Project: ${GREEN}$PROJECT_NAME${NC}"
echo -e "${BLUE}Region:  ${GREEN}$AWS_REGION${NC}"
