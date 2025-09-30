#!/bin/bash
set -e

# 🚀 AWS App Runner Deployment Script with Robust JSON Handling
# Assumes Docker image is already built and pushed to ECR by GitHub Actions
#
# Key improvements:
# - Uses jq for safe JSON construction (no string escaping issues)
# - Handles special characters and spaces in variables correctly
# - More maintainable and readable JSON configuration
# - Eliminates common deployment failures due to malformed JSON

# Check for required dependencies
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed"
    echo "   Install jq: apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
    exit 1
fi

# Load configuration from either location (GitHub Actions or local)
if [ -f ".github/config.env" ]; then
    source ".github/config.env"
    echo "📋 Loaded configuration from .github/config.env (GitHub Actions)"
elif [ -f "deployment/config.env" ]; then
    source "deployment/config.env"
    echo "📋 Loaded configuration from deployment/config.env (local)"
else
    echo "⚠️  No config.env found, using environment variables or defaults"
fi

# Configuration with validation
export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-YOUR_AWS_ACCOUNT_ID}"
export SERVICE_NAME="${SERVICE_NAME:-your-project-mxcp-server}"
export ECR_REPOSITORY="${ECR_REPOSITORY:-your-project-mxcp-server}"
export CPU_SIZE="${CPU_SIZE:-0.5 vCPU}"
export MEMORY_SIZE="${MEMORY_SIZE:-2 GB}"

# Validate critical configuration
if [[ "$AWS_ACCOUNT_ID" == "YOUR_AWS_ACCOUNT_ID" ]]; then
    echo "❌ Error: AWS_ACCOUNT_ID not configured properly"
    echo "   Please set it in deployment/config.env or as GitHub variable"
    exit 1
fi

if [[ "$SERVICE_NAME" == "your-project-mxcp-server" ]]; then
    echo "❌ Error: SERVICE_NAME not configured properly"
    echo "   Please set it in deployment/config.env or as GitHub variable APP_RUNNER_SERVICE"
    exit 1
fi

# Derived values
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export ECR_IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"

echo "🚀 Deploying MXCP Server to AWS App Runner"
echo "================================================"
echo "Service: $SERVICE_NAME"
echo "Region: $AWS_REGION"
echo "ECR Image: $ECR_IMAGE_URI"
echo "CPU: $CPU_SIZE"
echo "Memory: $MEMORY_SIZE"

# Build runtime environment variables JSON using jq (safe approach)
echo "📋 Discovering runtime variables from Docker image labels..."
RUNTIME_VARS=$(docker inspect "$ECR_IMAGE_URI" 2>/dev/null | jq -r '
  .[0].Config.Labels | 
  to_entries[] | 
  select(.key | startswith("env.runtime.")) | 
  select(.key | endswith(".json") | not) |
  .key | sub("env.runtime."; "")
' || echo "")

if [ -z "$RUNTIME_VARS" ]; then
    echo "⚠️  Could not extract runtime variables from image labels. Using defaults..."
    # Fallback to reasonable defaults if image inspection fails
    RUNTIME_VARS="OPENAI_API_KEY ANTHROPIC_API_KEY"
fi

# Build runtime environment JSON safely using jq
RUNTIME_ENV_JSON=$(jq -n \
  --arg port "8000" \
  --arg unbuffered "1" \
  '{
    "PORT": $port,
    "PYTHONUNBUFFERED": $unbuffered
  }')

# Add discovered runtime variables safely
for var in $RUNTIME_VARS; do
    if [ -n "${!var}" ]; then
        RUNTIME_ENV_JSON=$(echo "$RUNTIME_ENV_JSON" | jq \
          --arg key "$var" \
          --arg value "${!var}" \
          '. + {($key): $value}')
        echo "✅ Including runtime variable: $var"
    fi
done

echo "📋 Runtime environment configured ($(echo "$RUNTIME_ENV_JSON" | jq -r 'keys | length') variables)"
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
    
    # Update the service with new image and environment variables
    aws apprunner update-service \
        --service-arn "$SERVICE_ARN" \
        --source-configuration "$(jq -n \
            --arg image "$ECR_IMAGE_URI" \
            --arg account "$AWS_ACCOUNT_ID" \
            --argjson env_vars "$RUNTIME_ENV_JSON" \
            '{
                "ImageRepository": {
                    "ImageIdentifier": $image,
                    "ImageConfiguration": {
                        "Port": "8000",
                        "RuntimeEnvironmentVariables": $env_vars
                    },
                    "ImageRepositoryType": "ECR"
                },
                "AutoDeploymentsEnabled": false,
                "AuthenticationConfiguration": {
                    "AccessRoleArn": ("arn:aws:iam::" + $account + ":role/AppRunnerECRAccessRole")
                }
            }')"
    echo "✅ Service configuration updated"
    
    # Force deployment to pull latest image from ECR (even with same :latest tag)
    echo "🚀 Forcing deployment to pull latest image..."
    aws apprunner start-deployment --service-arn "$SERVICE_ARN"
    echo "✅ Deployment force-started - App Runner will pull fresh :latest image"
else
    echo "🆕 Creating new App Runner service..."
    aws apprunner create-service \
        --service-name "$SERVICE_NAME" \
        --source-configuration "$(jq -n \
            --arg image "$ECR_IMAGE_URI" \
            --arg account "$AWS_ACCOUNT_ID" \
            --argjson env_vars "$RUNTIME_ENV_JSON" \
            '{
                "ImageRepository": {
                    "ImageIdentifier": $image,
                    "ImageConfiguration": {
                        "Port": "8000",
                        "RuntimeEnvironmentVariables": $env_vars
                    },
                    "ImageRepositoryType": "ECR"
                },
                "AutoDeploymentsEnabled": false,
                "AuthenticationConfiguration": {
                    "AccessRoleArn": ("arn:aws:iam::" + $account + ":role/AppRunnerECRAccessRole")
                }
            }')" \
        --instance-configuration "$(jq -n \
            --arg cpu "$CPU_SIZE" \
            --arg memory "$MEMORY_SIZE" \
            '{
                "Cpu": $cpu,
                "Memory": $memory
            }')" \
        --health-check-configuration "$(jq -n \
            '{
                "Protocol": "HTTP",
                "Path": "/health",
                "Interval": 20,
                "Timeout": 5,
                "HealthyThreshold": 1,
                "UnhealthyThreshold": 3
            }')" \
        --region "$AWS_REGION"
fi

echo "✅ Deployment initiated!"
echo ""
echo "🔗 Service will be available at:"
SERVICE_URL=$(aws apprunner describe-service --service-arn "arn:aws:apprunner:${AWS_REGION}:${AWS_ACCOUNT_ID}:service/${SERVICE_NAME}" --query 'Service.ServiceUrl' --output text 2>/dev/null || echo "pending...")
echo "   https://$SERVICE_URL/mcp/"