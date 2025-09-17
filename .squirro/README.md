# Squirro Integration Directory

This directory contains templates and tools for deploying MXCP projects in Squirro's infrastructure.

## Recent Updates
- Updated for new testing structure (`test-tools`, `test-api`)
- Added support for project types (data, remote_data, api)
- Simplified eval commands (`mxcp evals` runs all tests)
- Added OPENAI_API_KEY to Docker build process
- Uses `just` task runner instead of individual scripts
- **IMPORTANT**: Now uses GitHub Variables (not secrets) for AWS configuration

## ⚠️ Important: Template Files

Most files in this directory are **TEMPLATES** that contain placeholders. They must be customized before use:
- `setup-for-squirro.sh.template` - Contains {{PROJECT_NAME}} placeholder
- `workflows/build-and-push-to-ecr.yml.template` - ECR deployment workflow

## Purpose

This directory provides:
1. **Templates** for Squirro-specific deployment configuration
2. **Scripts** to manage the integration between RAW Labs and Squirro repositories
3. **Documentation** for Squirro teams working with MXCP projects

## Workflow Overview

**Squirro's Deployment Pattern:**
1. **GitHub Actions** → Build and push Docker image to Squirro's ECR
2. **External system** → Automatically detects new ECR images
3. **Kubernetes** → Deploys the new image automatically

## How to Use These Templates

### For New Projects

1. **Copy and customize the setup script:**
```bash
cp .squirro/setup-for-squirro.sh.template .squirro/setup-for-squirro.sh
# Replace {{PROJECT_NAME}} with your actual project name
sed -i 's/{{PROJECT_NAME}}/your-project-name/g' .squirro/setup-for-squirro.sh
```

2. **Run the setup script:**
```bash
./.squirro/setup-for-squirro.sh
```

3. **Customize the generated files** for your environment (AWS account, ECR repo, etc.)

### For Ongoing Maintenance

Use `merge-from-raw.sh` to safely merge updates from RAW Labs while preserving your customizations:
```bash
./.squirro/merge-from-raw.sh
```

## Files in This Directory

### Templates (must be customized)
- `setup-for-squirro.sh.template` - Initial setup script template
- `ENVIRONMENT-GUIDE.md.template` - Deployment guide for your team
- `README.md.template` - Project-specific README for Squirro
- `workflows/build-and-push-to-ecr.yml.template` - GitHub Actions workflow

### Working Scripts (use as-is)
- `merge-from-raw.sh` - Merge updates from RAW Labs

## Configuration Requirements

### Base Configuration (deployment/config.env)
Default values are stored in `deployment/config.env`:
- Contains AWS account, region, ECR repository settings
- Tracked in git for documentation
- Can be overridden by GitHub Variables

### GitHub Variables (Repository Settings → Secrets and variables → Variables)
These are **optional overrides** for config.env values:
- `AWS_ACCOUNT_ID` - Override the AWS account ID from config.env
- `AWS_REGION` - Override the AWS region from config.env
- `ECR_REPOSITORY` - Override the ECR repository name from config.env
- `CPU_SIZE` - Override CPU allocation (e.g., "1 vCPU", "4 vCPU")
- `MEMORY_SIZE` - Override memory allocation (e.g., "2 GB", "8 GB")

### GitHub Secrets (Repository Settings → Secrets and variables → Secrets)
These are **sensitive** values that must be kept secret:
- `AWS_ACCESS_KEY_ID` - AWS credentials for ECR push
- `AWS_SECRET_ACCESS_KEY` - AWS credentials for ECR push
- `MXCP_DATA_ACCESS_KEY_ID` - For S3 data access (if needed)
- `MXCP_DATA_SECRET_ACCESS_KEY` - For S3 data access (if needed)
- `OPENAI_API_KEY` - For LLM functionality
- `ANTHROPIC_API_KEY` - Optional, for Claude models

## Required Customizations

When using these templates for your MXCP project:

1. **AWS Configuration** (`deployment/config.env`):
   - AWS_ACCOUNT_ID
   - AWS_REGION
   - ECR_REPOSITORY

2. **GitHub Secrets**:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - MXCP_DATA_ACCESS_KEY_ID (if using RAW's data)
   - MXCP_DATA_SECRET_ACCESS_KEY (if using RAW's data)

3. **Workflow Files**:
   - Update cluster names, namespaces, and deployment configurations

## Support

- **Template issues**: RAW Labs (pavlos@raw-labs.com)
- **MXCP questions**: RAW Labs Support
- **Squirro infrastructure**: Your DevOps team