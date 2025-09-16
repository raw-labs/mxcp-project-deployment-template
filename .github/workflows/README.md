# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the UAE MXCP Server project.

## Available Workflows

### 1. Configuration Validation (`test.yml`)
- **Trigger**: Pull requests to `main` branch, or manual dispatch
- **Purpose**: Quick validation of configuration files
- **What it runs**: `just validate-config`
  - YAML configuration validation
  - Tool definition syntax checks
- **Duration**: ~10 seconds
- **Requirements**: None (no secrets needed)

### 2. Deploy to AWS App Runner (`deploy.yml`)
- **Trigger**: Push to `main` branch, or manual dispatch
- **Purpose**: Complete build, deploy, and test pipeline
- **Workflow**:
  1. **validate-config**: Quick configuration validation
  2. **deploy**: Build Docker image, push to ECR, deploy to App Runner
  3. **test-deployment**: Post-deployment health and integration testing
- **Duration**: ~8-12 minutes
- **Requirements**: 
  - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets
  - `MXCP_DATA_ACCESS_KEY_ID` and `MXCP_DATA_SECRET_ACCESS_KEY` secrets (for data download)

### 3. Release Management (`release.yml`)
- **Trigger**: Manual dispatch or tag creation
- **Purpose**: Create releases and manage versioning
- **Duration**: ~2 minutes

## Workflow Details

### Environment Variables
The workflows use these environment variables (configured in the workflow files):
```yaml
env:
  AWS_REGION: eu-west-1
  AWS_ACCOUNT_ID: 684130658470
  ECR_REPOSITORY: uae-mxcp-server
  APP_RUNNER_SERVICE: uae-mxcp-server
```

### Modern Task Runner
All workflows use the `just` task runner for clean, maintainable task execution:
- `just validate-config` - Configuration validation (fallback)
- `just ci-tests-with-data` - Comprehensive CI tests with data download
- `just full-pipeline` - Complete development pipeline (test workflow)
- `just test-integration` - Post-deployment integration tests
- `just prepare-build` - Data download and dbt processing (Docker)

### Security
- **Secrets**: Stored in GitHub repository secrets
- **Data access**: Uses dedicated IAM user with minimal S3 permissions
- **Credentials**: Cleared from Docker image after data preparation

## Deployment Architecture

**RAW Labs Workflow:**
```
GitHub Actions → ECR → AWS App Runner → Health Check → Integration Test
```

**For Squirro Integration:**
- Squirro replaces these workflows with their own EKS-based deployment
- Uses the same build patterns but different deployment target
- External system handles ECR → Kubernetes deployment

## Troubleshooting

### Common Issues
1. **AWS credentials not configured**: Add secrets to repository
2. **Data download fails**: Check MXCP_DATA_ACCESS credentials
3. **App Runner deployment fails**: Check service limits and IAM roles
4. **Health checks fail**: Service may need more time to start

### Monitoring
- **GitHub Actions**: Check workflow logs for build/deploy issues
- **App Runner**: Monitor service status in AWS console
- **Health endpoint**: `https://service-url/health`
- **MCP endpoint**: `https://service-url/mcp`

## Best Practices

1. **Always test locally first**: Run `just full-pipeline` before pushing
2. **Monitor deployments**: Watch GitHub Actions and App Runner status
3. **Check health after deploy**: Verify service responds correctly
4. **Use manual dispatch**: For controlled deployments to staging/production