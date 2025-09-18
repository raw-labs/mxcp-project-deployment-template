# MXCP Project Deployment Template

> 🚀 **Standardized deployment infrastructure for MXCP projects with proven CI/CD patterns**

This template enables consistent deployment of MXCP servers across RAW Labs and external teams, with support for AWS App Runner and Kubernetes/Flux deployments.

## 🚀 Quick Start

```bash
# For new projects
cp -r mxcp-project-deployment-template/ my-new-project/
cd my-new-project
./setup-project.sh my-project-name

# For existing projects
cd existing-project
cp -r /path/to/template/.github .
cp -r /path/to/template/deployment .
./setup-project.sh my-project-name
```

## Table of Contents

- [Quick Start](#-quick-start)
- [Architecture Overview](#architecture-overview)
- [Purpose](#purpose)
- [Template Components](#template-components)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [For New MXCP Projects](#for-new-mxcp-projects)
  - [For Existing MXCP Projects](#for-existing-mxcp-projects)
- [Template Philosophy](#template-philosophy)
- [Justfile Guide](#justfile-guide)
  - [3-Tiered Testing Architecture](#3-tiered-testing-architecture)
  - [Template Placeholders](#template-placeholders)
  - [Available Tasks](#available-tasks)
- [Examples](#examples)
- [Integration Guide for DevOps Teams](#integration-guide-for-devops-teams)
  - [For RAW Labs Teams](#for-raw-labs-teams)
  - [For External Teams (Squirro)](#for-external-teams-squirro)
  - [Network and Service Discovery](#network-and-service-discovery)
  - [Environment Variables](#environment-variables)
  - [Production Checklist](#production-checklist)
- [Secret Management](#secret-management)
- [Monitoring and Observability](#monitoring-and-observability)
  - [Health Monitoring](#health-monitoring)
  - [Audit Logs](#audit-logs)
  - [Metrics and Dashboards](#metrics-and-dashboards)
- [Backup and Recovery](#backup-and-recovery)
- [Support](#support)

## Architecture Overview

```mermaid
graph TB
    %% GitHub Workflows
    subgraph "🚀 GitHub Workflows (.github/)"
        Deploy[".github/workflows/deploy.yml<br/>📋 Main CI/CD Pipeline"]
        Test[".github/workflows/test.yml<br/>🧪 PR Testing"]
        Release[".github/workflows/release.yml<br/>🏷️ Release Management"]
    end

    %% Justfile Tasks
    subgraph "⚡ Justfile Tasks (justfile)"
        ValidateConfig["just validate-config<br/>📝 YAML validation"]
        CiTests["just ci-tests-with-data<br/>🔍 CI tests + data"]
        FullPipeline["just full-pipeline<br/>🏗️ Complete dev pipeline"]
        TestTools["just test-tools<br/>🔧 Tool tests"]
        PrepareBuild["just prepare-build<br/>📦 Data preparation"]
        TestData["just test-data<br/>🧪 Level 1: dbt tests"]
        TestEvals["just test-evals<br/>🤖 Level 3: LLM evals"]
    end

    %% Deployment Files
    subgraph "🐳 Deployment (deployment/)"
        Dockerfile["Dockerfile<br/>🐳 Container build"]
        ConfigEnv["config.env.template<br/>⚙️ AWS configuration"]
        MxcpSite["mxcp-site-docker.yml.template<br/>🔧 MXCP config"]
        UserConfig["mxcp-user-config.yml.template<br/>🔐 Secrets & LLM keys"]
        StartSh["start.sh<br/>🚀 Container startup"]
    end

    %% Project Files
    subgraph "📁 Project Structure"
        Scripts["scripts/<br/>📜 Data download logic"]
        Tools["tools/<br/>🛠️ MXCP endpoints"]
        Models["models/<br/>📊 dbt transformations"]
    end

    %% Workflow Relationships
    Deploy -->|"1. Validation"| CiTests
    Deploy -->|"Fallback"| ValidateConfig
    Deploy -->|"2. Post-deployment"| TestTools
    
    Test -->|"PR Testing"| FullPipeline
    Test -->|"Fallback"| ValidateConfig

    %% Justfile Task Dependencies
    CiTests --> ValidateConfig
    CiTests --> PrepareBuild
    CiTests --> TestData
    
    FullPipeline --> PrepareBuild
    FullPipeline --> TestData
    FullPipeline --> TestTools
    
    TestTools -->|"Uses"| Tools
    TestData -->|"Tests"| Models

    %% Docker Build Process
    Dockerfile -->|"Installs just"| PrepareBuild
    PrepareBuild -->|"Downloads data"| Scripts
    PrepareBuild -->|"Runs dbt"| Models

    %% Configuration Flow
    ConfigEnv -->|"AWS settings"| Deploy
    MxcpSite -->|"MXCP config"| Dockerfile
    UserConfig -->|"Secrets"| Dockerfile

    %% 3-Tiered Testing
    subgraph "🎯 3-Tiered Testing"
        Level1["Level 1: Data Quality<br/>🧪 dbt schema tests<br/>💰 Free"]
        Level2["Level 2: Integration<br/>🔧 MXCP tools & API tests<br/>💰 Free"]
        Level3["Level 3: LLM Evaluation<br/>🤖 AI behavior tests<br/>💰 Costs Apply"]
    end

    TestData -.->|"Implements"| Level1
    TestTools -.->|"Implements"| Level2
    TestEvals -.->|"Implements"| Level3

    %% Styling
    classDef workflow fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef justfile fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef deployment fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef project fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef testing fill:#fce4ec,stroke:#880e4f,stroke-width:2px

    class Deploy,Test,Release workflow
    class ValidateConfig,CiTests,FullPipeline,TestTools,PrepareBuild,TestData,TestEvals justfile
    class Dockerfile,ConfigEnv,MxcpSite,UserConfig,StartSh deployment
    class Scripts,Tools,Models project
    class Level1,Level2,Level3 testing
```

### Understanding the Architecture

The diagram above shows how the template's components work together:

**🔄 Workflow Execution Flow:**
1. **GitHub Workflows** trigger **Justfile tasks** for consistent execution
2. **Justfile tasks** orchestrate the **3-tiered testing** approach
3. **Deployment files** configure the containerized environment
4. **Project files** contain your specific MXCP implementation

**🎯 Key Integration Points:**
- **Workflows → Justfile**: All CI/CD uses justfile tasks (no manual commands)
- **Justfile → Project**: Tasks operate on your scripts, models, and tools
- **Docker → Justfile**: Container build uses `just prepare-build` for data prep
- **Config → All**: Template files provide consistent configuration patterns

**💡 Benefits:**
- **Consistency**: Same tasks run locally and in CI/CD
- **Flexibility**: Graceful fallbacks for different project types
- **Maintainability**: Centralized task definitions in justfile
- **Testability**: 3-tiered approach from config validation to LLM evaluation

## Purpose

### Why Use This Template?

| Benefit | Description |
|---------|-------------|
| **🔧 Standardized CI/CD** | Same deployment logic across all MXCP projects |
| **🤝 Multi-team Support** | Works for RAW Labs, Squirro, and other external teams |
| **✅ Production Proven** | Powers UAE MXCP Server with 3M+ records |
| **🔄 Easy Updates** | Minimal merge conflicts, clear separation of concerns |
| **🏃 Fast Deployment** | From zero to deployed in under 10 minutes |
| **🔒 Security First** | Built-in secrets management and audit logging |

## Template Components

### 📁 Directory Structure

```
mxcp-project-deployment-template/
├── .github/                    # Stable CI/CD (rarely modified)
│   ├── workflows/              
│   │   ├── deploy.yml         # Main deployment pipeline
│   │   ├── test.yml           # PR testing workflow
│   │   └── release.yml        # Release management
│   └── scripts/
│       └── deploy-app-runner.sh # AWS deployment script
├── deployment/                 # Customizable configs
│   ├── config.env.template    # AWS settings
│   ├── Dockerfile             # Container build
│   ├── mxcp-site-docker.yml.template # MXCP config
│   ├── mxcp-user-config.yml.template # Secrets config
│   ├── profiles-docker.yml.template  # dbt profiles
│   ├── requirements.txt       # Python dependencies
│   └── start.sh              # Container startup
├── .squirro/                  # External team integration
│   ├── setup-for-squirro.sh.template
│   └── merge-from-raw.sh     
├── justfile.template          # Task runner config
├── setup-project.sh           # One-click setup
├── ENVIRONMENT.md.template    # Variable documentation
└── README.md                  # This file
```

## Prerequisites

### ✅ Required

| Component | Purpose | Setup Guide |
|-----------|---------|-------------|
| **AWS Account** | Deployment target | [AWS Free Tier](https://aws.amazon.com/free/) |
| **GitHub Account** | CI/CD and version control | [GitHub Signup](https://github.com/join) |
| **IAM Role** | `AppRunnerECRAccessRole` | See ENVIRONMENT.md |

### 🔑 Configuration Approach: Hybrid (config.env + GitHub Variables)

The template uses a **hybrid configuration approach**:
1. **Base defaults** are stored in `deployment/config.env` (tracked in git)
2. **Environment-specific overrides** use GitHub Variables  
3. **Secrets** always use GitHub Secrets (never in config.env)

This provides self-documenting configuration with secure overrides.

**GitHub Variables** (Settings → Secrets and variables → Actions → Variables):
```bash
# AWS deployment configuration (optional overrides for config.env values)
gh variable set AWS_ACCOUNT_ID --body "684130658470"    # Override AWS account ID
gh variable set AWS_REGION --body "eu-west-1"           # Override AWS region
gh variable set ECR_REPOSITORY --body "your-project-mxcp-server"
gh variable set APP_RUNNER_SERVICE --body "your-project-mxcp-server"
gh variable set CPU_SIZE --body "1 vCPU"                 # Override CPU allocation
gh variable set MEMORY_SIZE --body "4 GB"                # Override memory allocation
```

**GitHub Secrets** (Settings → Secrets and variables → Actions → Secrets):
```bash
# Deployment credentials
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY

# Data access (if using S3/external data)
gh secret set MXCP_DATA_ACCESS_KEY_ID
gh secret set MXCP_DATA_SECRET_ACCESS_KEY

# LLM APIs (if using AI features)
gh secret set OPENAI_API_KEY        # Optional
gh secret set ANTHROPIC_API_KEY     # Optional
```

### 🛠️ Local Development Tools

| Tool | Required | Installation |
|------|----------|--------------|
| Git | ✅ Yes | `apt install git` |
| Docker | ⚠️ Optional | [Docker Desktop](https://docker.com) |
| just | ⚠️ Recommended | `curl -sSf https://just.systems/install.sh \| bash` |

## Usage

### For New MXCP Projects

#### Quick Setup (Automated)

```bash
# Copy template to your project
cp -r /path/to/mxcp-project-deployment-template your-new-project/
cd your-new-project

# Run automated setup (steps 2-4)
./setup-project.sh --name your-project-name [options]

# Examples:
./setup-project.sh --name finance-demo
./setup-project.sh --name uae-licenses --region us-west-2 --type remote_data
./setup-project.sh --name vertec-poc --type api

# Legacy format (still supported):
./setup-project.sh finance-demo
./setup-project.sh uae-licenses us-west-2

# ℹ️ dbt Integration: The script automatically updates dbt_project.yml 
# to use profile '{{PROJECT_NAME}}-mxcp' matching the generated profiles.yml

# ⚠️ Important: The script also handles .gitignore to ensure deployment files
# are tracked in git (required for CI/CD to work)

# Project Types:
# - data: Local data files in data/ directory (default)
# - remote_data: Data downloaded from external sources (S3, etc.)
# - api: API-based project with no static data or dbt models

# Note: The script automatically removes all .template files and itself after
# successful setup to keep your project clean
```

#### MXCP Configuration

The `deployment/mxcp-user-config.yml` file configures LLM models and secrets:

```yaml
# LLM Models Configuration (REQUIRED FORMAT)
models:
  default: gpt-4o        # Default model to use
  models:                # Nested models object
    gpt-4o:
      type: openai       # Use 'type' not 'provider'
      api_key: ${OPENAI_API_KEY}
    gpt-3.5-turbo:
      type: openai
      api_key: ${OPENAI_API_KEY}
    # Add other OpenAI models as needed (claude-3-opus, etc.)

# Project secrets configuration
projects:
  "{{PROJECT_NAME}}-mxcp":
    profiles:
      prod:
        secrets:
          - name: "example-secret"
            type: "custom"
            parameters:
              param_a: "value_a"
              param_b: "value_b"
```

⚠️ **Common Configuration Errors:**
- Using flat model structure instead of `models.default` + `models.models`
- Using `provider:` instead of `type:` for model configuration
- Adding unsupported properties like `secrets: {}` at top level
- Forgetting quotes around project names with special characters

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

# Customize placeholders for your project (see Justfile Guide below)
sed -i "s/{{PROJECT_NAME}}/your-project/g" justfile
# Add your specific data download and dbt commands...

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

**6. Clean Up Template Files (Optional)**
```bash
# Remove .template files after customization to keep your project clean
rm -f justfile.template
rm -f deployment/*.template
rm -f ENVIRONMENT.md.template
```

**7. Choose Your Data Strategy**

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

### Customizing Secrets for Your Project

Each project must customize `.github/workflows/deploy.yml` to include its specific secrets:

1. Open `.github/workflows/deploy.yml`
2. Find the `env:` block at the top (after the `on:` section)
3. Add your project's secrets:
   ```yaml
   env:
     # Your project's secrets
     OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY || '' }}
     ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY || '' }}
     CUSTOM_API_TOKEN: ${{ secrets.CUSTOM_API_TOKEN || '' }}
   ```
4. Commit these changes - they're part of your project configuration

**Why this approach?**
- Simple and explicit - you see exactly what secrets your project uses
- No complex template processing or filtering
- GitHub Actions requires explicit secret references anyway
- Easy to add new secrets as your project evolves

### Critical: .gitignore Configuration

⚠️ **IMPORTANT**: The deployment files MUST be tracked in git for CI/CD to work!

When using this template in your project, ensure these files are **NOT** in your `.gitignore`:
- `deployment/config.env`
- `deployment/mxcp-user-config.yml`
- `deployment/mxcp-site-docker.yml`
- `deployment/profiles-docker.yml`
- `justfile`

The `setup-project.sh` script automatically handles this, but if you're setting up manually:

```bash
# Remove these entries from .gitignore if present
sed -i '/^deployment\/config\.env$/d' .gitignore
sed -i '/^deployment\/mxcp-user-config\.yml$/d' .gitignore
sed -i '/^deployment\/mxcp-site-docker\.yml$/d' .gitignore
sed -i '/^deployment\/profiles-docker\.yml$/d' .gitignore
sed -i '/^justfile$/d' .gitignore
```

**Why this matters**: During CI/CD, GitHub Actions clones your repository and builds the Docker image. If these files are gitignored, they won't exist in the clone, causing the Docker build to fail with "file not found" errors.

## For Existing MXCP Projects

#### Scenario 1: Project Without CI/CD

If you have an MXCP project with just core files but no deployment:

```bash
# Copy template infrastructure
cd your-existing-project
cp -r /path/to/template/.github .
cp -r /path/to/template/deployment .
cp /path/to/template/justfile.template .
cp /path/to/template/setup-project.sh .

# Run setup
./setup-project.sh your-project-name

# Configure and deploy
git add .
git commit -m "Add deployment infrastructure"
git push origin main
```

#### Scenario 2: Project With Different CI/CD

For selective adoption:

```bash
# Compare components before replacing
diff -r .github/workflows /path/to/template/.github/workflows

# Adopt what makes sense
cp /path/to/template/.github/workflows/deploy.yml .github/workflows/
cp /path/to/template/deployment/Dockerfile deployment/

# Or run full setup for complete standardization
./setup-project.sh your-project-name
```

#### Scenario 3: External Teams (Squirro)

```bash
# Copy Squirro integration
cp -r /path/to/template/.squirro .

# Run setup
./.squirro/setup-for-squirro.sh

# Use merge script for updates
./.squirro/merge-from-raw.sh
```

## Template Philosophy

- **`.github/` = PROJECT-CUSTOMIZED** - Add your project's secrets to the `env:` block
- **`.squirro/` = SQUIRRO-SPECIFIC** - Tools and workflows for Squirro integration
- **`deployment/` = CUSTOMIZABLE** - Projects modify configuration files
- **`justfile.template` = GENERIC** - Uses placeholders for project-specific commands:
  - `{{DATA_DOWNLOAD_COMMAND}}` - How to download your project's data
  - `{{DBT_DEPS_COMMAND}}` - Install dbt dependencies (or skip for API projects)
  - `{{DBT_RUN_COMMAND}}` - How to run dbt with your data variables
  - `{{DBT_TEST_COMMAND}}` - How to test dbt with your data variables
- **Simplicity over standardization** - Each project customizes what it needs

## Justfile Guide

The template includes a modern task runner (`justfile.template`) that provides a standardized way to run common MXCP operations. This replaces scattered shell scripts with clean, documented tasks.

### 3-Tiered Testing Architecture

The justfile implements a comprehensive testing strategy with three levels:

| Level | Type | Purpose | Cost | When Run | Command |
|-------|------|---------|------|----------|---------|
| **Build** | Config Validation | YAML syntax, basic setup | Free | During Docker build | `just test-config` |
| **Level 1** | Data Quality | dbt schema tests, referential integrity | Free | After build | `just test-data` |
| **Level 2** | Tool Tests | MXCP tools functionality (`python tests/test.py tool`) | Free | After build | `just test-tools` |
| **Level 2** | API Tests | External API integration (`python tests/test.py api`) | Free | After build | `just test-api` |
| **Level 3** | LLM Evaluation | End-to-end AI behavior validation | $$$ | After build | `just test-evals` |

**Important**: Full testing (Levels 1-3) happens AFTER the Docker build, when secrets are available. This ensures we never bake secrets into the Docker image.

### Template Placeholders

When customizing `justfile.template`, replace these placeholders with your project-specific commands:

#### **{{PROJECT_NAME}}** 
Replace with your project name (e.g., "uae-licenses", "finance-demo"):
```bash
sed -i "s/{{PROJECT_NAME}}/your-project/g" justfile
```

> **ℹ️ dbt Integration**: The setup script automatically creates a dbt profile named `{{PROJECT_NAME}}-mxcp` 
> and updates your `dbt_project.yml` to match. No manual synchronization needed!

#### **{{DATA_DOWNLOAD_COMMAND}}**
Replace with your data download command:

**Example (S3 download):**
```bash
python3 scripts/download_real_data.py --output data/licenses.csv
```

**Example (API fetch):**
```bash
python3 scripts/fetch_from_api.py --output data/records.csv
```

**Example (Static data):**
```bash
echo "Using static data - no download needed"
```

#### **{{DBT_DEPS_COMMAND}}**
Install dbt dependencies (or skip for API projects):

**Example (data projects):**
```bash
dbt deps
```

**Example (API projects):**
```bash
echo "🔌 API-based project - no dbt dependencies"
```

#### **{{DBT_RUN_COMMAND}}**
Replace with your dbt run command:

**Example (with variables):**
```bash
dbt run --vars '{"licenses_file": "data/licenses.csv"}'
```

**Example (simple):**
```bash
dbt run
```

#### **{{DBT_TEST_COMMAND}}**
Replace with your dbt test command:

**Example (with variables):**
```bash
dbt test --vars '{"licenses_file": "data/licenses.csv"}'
```

**Example (simple):**
```bash
dbt test
```

#### **{{API_TEST_COMMAND}}**
Replace with your API test command (for API-based projects).

**For API projects:**
```bash
python tests/test.py api
```

**For data projects (default):**
```bash
@echo '📊 Data project - no API tests needed'
```

#### **{{MXCP_EVALS_COMMANDS}}**
Replace with your MXCP evaluation commands.

⚠️ **Important**: The command is prefixed with `-` to make failures non-blocking.

**Default (runs all evals):**
```bash
-mxcp evals
```

**Legacy format (specific eval suites):**
```bash
-mxcp evals basic_test
-mxcp evals search_functionality
-mxcp evals edge_cases
```

### UAE MXCP Server Example

Here's how the UAE project customized the template:

```bash
# UAE-specific customization
PROJECT_NAME="uae-licenses"
DATA_DOWNLOAD_COMMAND="python3 scripts/download_real_data.py --output data/licenses.csv"
DBT_RUN_COMMAND='dbt run --vars '"'"'{"licenses_file": "data/licenses.csv"}'"'"''
DBT_TEST_COMMAND='dbt test --vars '"'"'{"licenses_file": "data/licenses.csv"}'"'"''
MXCP_EVALS_COMMANDS="-mxcp evals"  # Runs all eval suites
```

### Available Tasks

After customization, your justfile will provide these tasks:

#### **Data Pipeline Tasks**
- `just download` - Download/prepare your project data
- `just build-models` - Run dbt transformations  
- `just prepare-build` - Complete data preparation for Docker

#### **Testing Tasks (3-Tier)**
- `just test-config` - Validate YAML configurations (instant)
- `just test-data` - Run dbt data quality tests (Level 1)
- `just test-tools` - Test MXCP tools functionality (Level 2)
- `just test-api` - Test external API integration (Level 2, API projects)
- `just test-evals` - Run LLM evaluation tests (Level 3, costs apply)
- `just test-all` - Run all testing levels

#### **Development Workflows**
- `just dev` - Standard development pipeline (Levels 1+2, free)
- `just dev-full` - Full development pipeline (Levels 1+2+3, costs apply)
- `just full-pipeline` - Complete ETL + testing pipeline
- `just ci-tests-with-data` - CI-ready tests with data download

#### **Utility Tasks**
- `just validate-config` - Quick YAML validation (no data needed)
- `just` or `just --list` - Show all available tasks

### Usage Examples

```bash
# Quick development cycle (free)
just dev                    # Download data + build + test Levels 1+2

# Full validation before release (costs apply)  
just dev-full              # Download data + build + test all 3 levels

# Individual testing levels
just test-data             # Level 1: dbt schema tests
just test-tools            # Level 2: MXCP tools tests  
just test-evals           # Level 3: LLM evaluation tests (requires OPENAI_API_KEY)

# CI/CD pipeline
just ci-tests-with-data    # Standard CI tests with data
```

### Cost Management

**Level 3 (LLM Evaluation) costs apply:**
- Requires `OPENAI_API_KEY` environment variable
- Each eval run costs ~$0.10-$2.00 depending on complexity
- Use `just test-evals` sparingly (before releases, not every commit)
- Use `just dev` for daily development (excludes Level 3)

## Examples

### 🏆 Success Story: UAE Business Licenses

| Metric | Value |
|--------|-------|
| **Repository** | [uae-mxcp-server](https://github.com/raw-labs/uae-mxcp-server) |
| **Live Service** | [App Runner Deployment](https://sqt3yghjpw.eu-west-1.awsapprunner.com) |
| **Data Scale** | 3,186,320 business licenses |
| **Performance** | 4 vCPU, 8GB RAM |
| **Deployment Time** | < 10 minutes |
| **Merge Conflicts** | Zero during RAW-Squirro collaboration |

## Troubleshooting Common Issues

### Docker Build Failures

#### "File not found" errors
```
COPY failed: file not found in build context
```
**Cause**: Deployment files are in `.gitignore`
**Fix**: Ensure deployment files are tracked in git (see [Critical: .gitignore Configuration](#critical-gitignore-configuration))

#### "Invalid user config" errors
```
Error: Invalid user config: Additional properties are not allowed
```
**Cause**: Incorrect MXCP configuration format
**Fix**: Check `deployment/mxcp-user-config.yml` follows the [correct format](#mxcp-configuration)

#### "Model not configured" errors
```
Error: Model 'gpt-4.1' not configured in user config
```
**Cause**: Eval tests reference a model not in config
**Fix**: Either:
1. Add the model to `mxcp-user-config.yml` (if it's a real model)
2. Update the eval test to use an existing model (e.g., change gpt-4.1 to gpt-4o)
3. Make the eval command non-blocking with `-` prefix

### CI/CD Issues

#### Eval tests causing build failures
**Cause**: Eval test failures blocking deployment
**Fix**: Ensure all `mxcp evals` commands in justfile have `-` prefix:
```make
test-evals:
    -mxcp evals test1  # Note the - prefix
    -mxcp evals test2  # Makes failures non-blocking
```

#### Missing GitHub Variables
**Cause**: GitHub Variables not set for the repository
**Fix**: Set all required variables:
```bash
gh variable set AWS_ACCOUNT_ID --body "684130658470"
gh variable set AWS_REGION --body "eu-west-1"
gh variable set ECR_REPOSITORY --body "your-project-mxcp-server"
gh variable set APP_RUNNER_SERVICE --body "your-project-mxcp-server"
```

## Integration Guide for DevOps Teams

### Overview

This template enables standardized deployment of MXCP servers with proven patterns for both RAW Labs and external teams (like Squirro). The architecture supports:

- **Standardized CI/CD** with AWS App Runner or external systems
- **Flexible data strategies** (static, downloaded, or API-based)
- **Health check architecture** proven with 3M+ record deployments
- **Clean separation** between stable infrastructure and customizable components

### For RAW Labs Teams

1. **Create new MXCP project from template:**
```bash
cp -r mxcp-project-deployment-template/ new-project/
cd new-project
./setup-project.sh project-name
```

2. **Implement project logic:**
- Add tools in `tools/`
- Create data scripts in `scripts/`
- Set up dbt models in `models/`

3. **Deploy:**
```bash
git push origin main  # Triggers automatic deployment
```

### For External Teams (Squirro)

1. **Fork the project repository** (not this template)
2. **Run Squirro setup:**
```bash
./.squirro/setup-for-squirro.sh
```
3. **Customize for your infrastructure:**
- Update `deployment/config.env`
- Modify data sources if needed
- Configure your deployment system

4. **Merge updates from RAW:**
```bash
./.squirro/merge-from-raw.sh
```

### Network and Service Discovery

**Port Configuration:**
- External: Port 8000 (health checks + MCP proxy)
- Internal: Port 8001 (MXCP server)

**Health Architecture:**
```
Client → :8000/health → 200 OK (App Runner/K8s health)
Client → :8000/mcp/* → Proxy → :8001 (MXCP server)
```

### Environment Variables

Each project should document its specific requirements:
- **AWS Configuration**: Set in `deployment/config.env`
- **Secrets**: Use GitHub Secrets, Vault, or 1Password
- **API Keys**: Configure in `deployment/mxcp-user-config.yml`

### Production Checklist

- [ ] Set up AWS credentials and GitHub secrets
- [ ] Configure `deployment/config.env` with your values
- [ ] Test locally with `just full-pipeline`
- [ ] Deploy with `git push origin main`
- [ ] Verify health endpoint responds
- [ ] Check CloudWatch logs for audit trail

## Secret Management

MXCP supports multiple secret management solutions:

### HashiCorp Vault
```bash
# Set Vault address and token
export VAULT_ADDR="https://vault.example.com"
export VAULT_TOKEN="your-vault-token"

# Store secrets
vault kv put secret/mxcp/{{project}} \
  OPENAI_API_KEY="sk-..." \
  ANTHROPIC_API_KEY="sk-ant-..."
```

### 1Password Connect
```bash
# Set service account token
export OP_SERVICE_ACCOUNT_TOKEN="your-token"
# MXCP can reference op:// paths in config
```

### GitHub Secrets (Recommended for CI/CD)
```bash
gh secret set OPENAI_API_KEY --body "sk-..."
gh secret set AWS_ACCESS_KEY_ID --body "AKIA..."
```

## Monitoring and Observability

### Health Monitoring
- **Endpoint**: `GET /health` returns JSON status
- **Frequency**: Configure based on your SLA (default: 30s)
- **Timeout**: Keep low for fast failure detection (5s)

### Audit Logs

MXCP generates structured audit logs in JSONL format:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "session_id": "uuid",
  "trace_id": "otel-trace-id", 
  "operation_name": "tool_name",
  "caller": "user_identifier",
  "duration_ms": 145,
  "status": "success"
}
```

**Log Shipping Options:**
- CloudWatch Logs (AWS native)
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Splunk
- Datadog
- Grafana Loki

**Log Rotation:**
```bash
# /etc/logrotate.d/mxcp
/app/logs/*.jsonl {
    daily
    rotate 30
    compress
    notifempty
}
```

### Metrics and Dashboards

Key metrics to monitor:
- Request latency (p50, p90, p99)
- Error rate by tool
- Token usage (for LLM tools)
- Memory/CPU utilization
- Active sessions

## Backup and Recovery

MXCP is mostly stateless, but consider backing up:

1. **Audit Logs** - Historical usage data
2. **Configuration** - Your customized YAML files (in Git)
3. **Data** - If using local data files

Recovery is straightforward:
```bash
# Restore from Git
git clone your-repo
./setup-project.sh your-project

# Restore secrets from vault
vault kv get secret/mxcp/your-project

# Deploy
git push origin main
```

## Support

### What RAW Labs Provides
- Template maintenance and updates
- Bug fixes in MXCP framework
- Technical guidance and best practices
- Documentation and examples

### What Teams Handle
- Infrastructure and deployment
- Secret management
- Monitoring and alerting
- Scaling and performance tuning

### Contacts
- **Technical Questions**: Pavlos Polydoras (pavlos@raw-labs.com)
- **Template Issues**: Ben (ben@raw-labs.com)
- **Documentation**: https://mxcp.dev/docs/
