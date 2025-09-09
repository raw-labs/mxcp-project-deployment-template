# MXCP Project Deployment Template

This repository provides standardized deployment infrastructure for MXCP projects, enabling consistent CI/CD and deployment patterns across all RAW Labs MXCP implementations.

## Purpose

**Template Architecture Benefits:**
- **Standardized CI/CD** - Same deployment logic across all MXCP projects
- **Easy Squirro collaboration** - Clear separation between stable templates and customizable configuration
- **Proven patterns** - Based on successful production deployments
- **Minimal merge conflicts** - Template files rarely change

## Template Components

### Stable Components (.github/)
**Never modified by project teams:**
- `workflows/deploy.yml` - Generic CI/CD pipeline for AWS App Runner
- `workflows/test.yml` - Standardized testing workflow
- `scripts/deploy-app-runner.sh` - App Runner deployment logic
- `workflows/release.yml` - Release management

### Customizable Components (deployment/)
**Modified for each project:**
- `config.env.template` - AWS account, ECR repository, service names
- `mxcp-site-docker.yml.template` - MXCP configuration with project name
- `profiles-docker.yml.template` - dbt profiles with project name
- `Dockerfile` - Generic container build pattern
- `start.sh` - Generic container startup script
- `requirements.txt` - Base MXCP dependencies

## Prerequisites

### AWS Setup
1. **AWS Account** with App Runner service access
2. **IAM Role**: `AppRunnerECRAccessRole` with ECR access permissions
3. **Repository Secrets** in GitHub:
   - `AWS_ACCESS_KEY_ID` - For deployment access
   - `AWS_SECRET_ACCESS_KEY` - For deployment access
   - `MXCP_DATA_ACCESS_KEY_ID` - For data download (if needed)
   - `MXCP_DATA_SECRET_ACCESS_KEY` - For data download (if needed)

### Required Tools
- **Git** - For repository management
- **Docker** - For local testing (optional)
- **just** - Modern task runner (optional but recommended)

## Usage

### For New MXCP Projects

#### Quick Setup (Automated)

```bash
# Copy template to your project
cp -r /path/to/mxcp-project-deployment-template your-new-project/
cd your-new-project

# Run automated setup (steps 2-4)
./setup-project.sh your-project-name [aws-region]

# Example:
./setup-project.sh finance-demo
./setup-project.sh uae-licenses us-west-2
```

#### Manual Setup (Step by Step)

**1. Copy Template Components**
```bash
# Copy the stable and customizable directories to your new project
cp -r /path/to/mxcp-project-deployment-template/.github your-new-project/
cp -r /path/to/mxcp-project-deployment-template/deployment your-new-project/
```

**2. Customize Configuration**
```bash
cd your-new-project

# Customize deployment configuration
cp deployment/config.env.template deployment/config.env
vim deployment/config.env

# Set your values:
# AWS_ACCOUNT_ID=your-aws-account
# AWS_REGION=your-region  
# ECR_REPOSITORY=your-project-mxcp-server
# APP_RUNNER_SERVICE=your-project-mxcp-server
```

**3. Setup Task Runner (Optional but Recommended)**
```bash
# Copy and customize the modern task runner
cp justfile.template justfile
sed -i "s/{{PROJECT_NAME}}/your-project/g" justfile

# Install just (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

**4. Customize Docker Configuration**
```bash
# Update MXCP configuration
cp deployment/mxcp-site-docker.yml.template deployment/mxcp-site-docker.yml
sed -i "s/{{PROJECT_NAME}}/your-project/g" deployment/mxcp-site-docker.yml

# Update dbt profiles
cp deployment/profiles-docker.yml.template deployment/profiles-docker.yml
sed -i "s/{{PROJECT_NAME}}/your-project/g; s/{{AWS_REGION}}/your-region/g" deployment/profiles-docker.yml
```

**5. Initialize MXCP Project Structure**
```bash
# Initialize MXCP project with example endpoints
mxcp init --bootstrap

# This creates:
# - mxcp-site.yml (main configuration)
# - tools/ directory with example endpoints
# - Basic project structure
```

**6. Choose Your Data Strategy**

The template supports three data patterns:

**Option A: Static Data (simplest)**
```bash
# Place your data files in data/ directory
mkdir -p data/
# Copy your CSV/JSON files here
# Modify Dockerfile to skip download step
```

**Option B: Downloaded Data**
```bash
# Create data download script (customize for your source)
mkdir -p scripts/
# Create scripts/download_real_data.py for your data source (S3, API, etc.)
# Docker will run this during build
```

**Option C: Live API Integration**
```bash
# No data download needed - your tools connect to live APIs
# Remove data download from Dockerfile
# Configure API endpoints in your tools/
```

**7. Deploy**
```bash
# Set GitHub repository secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
# Push to trigger automatic deployment
git push origin main
```

## Template Philosophy

- **`.github/` = STABLE** - Rarely changes, provides consistent CI/CD
- **`deployment/` = CUSTOMIZABLE** - Projects modify configuration files
- **Clear separation** - Teams know exactly what to customize vs what to keep

## Examples

### Successful Implementation
- **UAE Business Licenses**: https://github.com/raw-labs/uae-mxcp-server
- **Live Service**: https://sqt3yghjpw.eu-west-1.awsapprunner.com
- **Records**: 3,186,320 UAE business licenses
- **Configuration**: 4 vCPU, 8GB memory

### Template Benefits Proven
- **Zero merge conflicts** during RAW-Squirro collaboration
- **Consistent deployment** across all MXCP projects  
- **Easy customization** - Only edit deployment/config.env
- **Automatic CI/CD** - Works out of the box

## Support

For questions about using this template:
- **Technical**: Pavlos Polydoras (pavlos@raw-labs.com)
- **Integration**: RAW Labs Support
- **Documentation**: https://github.com/raw-labs/mxcp-squirro-devops-integration-guide
