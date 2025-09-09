#!/bin/bash
set -e

# 🚀 Simplified AWS App Runner Deployment Script
# Assumes Docker image is already built and pushed to ECR by GitHub Actions

# Load configuration from deployment directory (keeps .github stable)
if [ -f "deployment/config.env" ]; then
    source "deployment/config.env"
    echo "📋 Loaded configuration from deployment/config.env"
else
    echo "⚠️  No deployment/config.env found, using defaults"
fi

# Default configuration (override in deployment/config.env)
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-YOUR_AWS_ACCOUNT_ID}"
export SERVICE_NAME="${SERVICE_NAME:-your-project-mxcp-server}"
export ECR_REPOSITORY="${ECR_REPOSITORY:-your-project-mxcp-server}"

# Derived values
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export ECR_IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"

echo "🚀 Deploying MXCP Server to AWS App Runner"
echo "================================================"
echo "Service: $SERVICE_NAME"
echo "Region: $AWS_REGION"
echo "ECR Image: $ECR_IMAGE_URI"
echo ""

# Step 1: Cleanup failed services (BEGINNING of deployment process)
echo "🧹 Checking for failed services to clean up..."
SERVICE_ARN="arn:aws:apprunner:${AWS_REGION}:${AWS_ACCOUNT_ID}:service/${SERVICE_NAME}"

if SERVICE_INFO=$(aws apprunner describe-service --service-arn "$SERVICE_ARN" 2>/dev/null); then
    SERVICE_STATUS=$(echo "$SERVICE_INFO" | jq -r '.Service.Status')
    echo "📋 Found existing service with status: $SERVICE_STATUS"
    
    if [[ "$SERVICE_STATUS" == "CREATE_FAILED" || "$SERVICE_STATUS" == "UPDATE_FAILED" || "$SERVICE_STATUS" == "DELETE_FAILED" ]]; then
        echo "🗑️  Cleaning up failed service ($SERVICE_STATUS) before deployment..."
        aws apprunner delete-service --service-arn "$SERVICE_ARN"
        
        # Wait for deletion to complete
        echo "⏳ Waiting for cleanup to complete..."
        while aws apprunner describe-service --service-arn "$SERVICE_ARN" >/dev/null 2>&1; do
            echo "   Still cleaning up... waiting 10 seconds"
            sleep 10
        done
        echo "✅ Cleanup completed - ready for fresh deployment"
    else
        echo "✅ Existing service is in good state ($SERVICE_STATUS)"
    fi
else
    echo "📋 No existing service found - ready for fresh deployment"
fi

# Step 2: Deploy (CLEAN SLATE)
echo "🚀 Deploying to App Runner..."

# Check current state after cleanup
if SERVICE_INFO=$(aws apprunner describe-service --service-arn "$SERVICE_ARN" 2>/dev/null); then
    SERVICE_STATUS=$(echo "$SERVICE_INFO" | jq -r '.Service.Status')
    echo "📝 Updating existing service (status: $SERVICE_STATUS)..."
    
    if [ "$SERVICE_STATUS" == "OPERATION_IN_PROGRESS" ]; then
        echo "⚠️  Another operation is in progress, cannot deploy now"
        exit 1
    fi
    
    aws apprunner start-deployment --service-arn "$SERVICE_ARN"
    echo "✅ Update deployment initiated"
else
    echo "🆕 Creating new App Runner service..."
    aws apprunner create-service \
        --service-name $SERVICE_NAME \
        --source-configuration '{
            "ImageRepository": {
                "ImageIdentifier": "'$ECR_IMAGE_URI'",
                "ImageConfiguration": {
                    "Port": "8000",
                    "RuntimeEnvironmentVariables": {
                        "PORT": "8000",
                        "PYTHONUNBUFFERED": "1"
                    }
                },
                "ImageRepositoryType": "ECR"
            },
            "AutoDeploymentsEnabled": false,
            "AuthenticationConfiguration": {
                "AccessRoleArn": "arn:aws:iam::'$AWS_ACCOUNT_ID':role/AppRunnerECRAccessRole"
            }
        }' \
        --instance-configuration '{
            "Cpu": "4 vCPU",
            "Memory": "8 GB"
        }' \
        --health-check-configuration '{
            "Protocol": "HTTP",
            "Path": "/health",
            "Interval": 20,
            "Timeout": 5,
            "HealthyThreshold": 1,
            "UnhealthyThreshold": 3
        }' \
        --region $AWS_REGION
fi

echo "✅ Deployment initiated!"
echo ""
echo "🔗 Service will be available at:"
SERVICE_URL=$(aws apprunner describe-service --service-arn "arn:aws:apprunner:${AWS_REGION}:${AWS_ACCOUNT_ID}:service/${SERVICE_NAME}" --query 'Service.ServiceUrl' --output text 2>/dev/null || echo "pending...")
echo "   https://$SERVICE_URL/mcp/"