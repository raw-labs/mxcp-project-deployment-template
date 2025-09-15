# Squirro Integration for UAE MXCP Server

This directory contains Squirro-specific tools and configurations for deploying the UAE MXCP Server in Squirro's infrastructure.

## Overview

**Squirro's Deployment Workflow:**
1. **GitHub Actions** → Build and push Docker image to Squirro's ECR
2. **External deployment system** → Automatically detects new ECR images and deploys to Kubernetes
3. **No manual K8s deployment** → Squirro's system handles deployment automatically

## Files in this Directory

### setup-for-squirro.sh
- **Purpose**: One-time setup when Squirro first forks this repository
- **What it does**: Configures the repository for Squirro's environment
- **When to run**: Once, after forking from RAW Labs

### merge-from-raw.sh  
- **Purpose**: Get updates from RAW Labs while preserving Squirro configurations
- **What it does**: Safely merges RAW's updates without overwriting Squirro customizations
- **When to run**: When RAW Labs releases updates

## Squirro Customization Points

**Required customizations for Squirro environment:**

### 1. deployment/config.env
```bash
# Set Squirro's AWS account and ECR repository
AWS_ACCOUNT_ID=your-squirro-account
AWS_REGION=your-region
ECR_REPOSITORY=uae-mxcp-server-squirro
```

### 2. GitHub Repository Configuration
**Variables** (Settings → Variables):
- `AWS_ACCOUNT_ID` - Your AWS account
- `AWS_REGION` - Your preferred region  
- `ECR_REPOSITORY` - Your ECR repository name

**Secrets** (Settings → Secrets):
- `AWS_ACCESS_KEY_ID` - Your CI/CD access key
- `AWS_SECRET_ACCESS_KEY` - Your CI/CD secret key
- `MXCP_DATA_ACCESS_KEY_ID` - Data access (optional - can use RAW's)
- `MXCP_DATA_SECRET_ACCESS_KEY` - Data access secret (optional)

### 3. Data Sources (Optional)
**scripts/prepare-data-for-build.sh:**
- Default: Downloads from RAW's S3 bucket
- Option: Customize for Squirro's data sources

## Deployment Workflow

### Development Cycle
1. **Develop**: Make changes to UAE MXCP server
2. **Test**: Run `just full-pipeline` locally  
3. **Push**: `git push origin main`
4. **GitHub Actions**: Builds and pushes to ECR automatically
5. **External system**: Detects new image and deploys to K8s automatically

### Getting RAW Updates
```bash
# When RAW Labs releases updates
./.squirro/merge-from-raw.sh

# Test the merged changes
just full-pipeline

# Push to trigger automatic deployment
git push origin main
```

## Support

- **MXCP issues**: RAW Labs (pavlos@raw-labs.com)
- **Integration questions**: RAW Labs Support
- **Infrastructure issues**: Squirro DevOps team