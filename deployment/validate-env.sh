#!/bin/bash
# Runtime environment validation for MXCP containers
# This script runs at container startup to ensure required variables are set

set -e

echo "🔍 Validating environment variables..."

# Always required
REQUIRED_VARS="OPENAI_API_KEY"

# Check project type if available
if [ -f /app/.project-type ]; then
    PROJECT_TYPE=$(cat /app/.project-type)
    echo "📋 Project type: $PROJECT_TYPE"
    
    case "$PROJECT_TYPE" in
        "remote_data")
            REQUIRED_VARS="$REQUIRED_VARS MXCP_DATA_ACCESS_KEY_ID MXCP_DATA_SECRET_ACCESS_KEY"
            ;;
        "api")
            # Add API-specific vars if needed
            ;;
    esac
fi

# Validate required variables
MISSING_VARS=""
for var in $REQUIRED_VARS; do
    if [ -z "${!var}" ]; then
        MISSING_VARS="$MISSING_VARS $var"
    fi
done

if [ -n "$MISSING_VARS" ]; then
    echo "❌ ERROR: Required environment variables are not set:$MISSING_VARS"
    echo ""
    echo "📋 To see all required/optional variables for this image:"
    echo "   docker inspect <image> | jq '.[] | .Config.Labels | to_entries[] | select(.key | startswith(\"env.\"))'"
    echo ""
    echo "🔐 Set these as secrets in your deployment system:"
    echo "   - GitHub Actions: Repository Secrets"
    echo "   - Kubernetes: Secret objects"
    echo "   - Docker: --env-file or -e flags"
    exit 1
fi

echo "✅ All required environment variables are set"

# Optional: Check recommended variables
OPTIONAL_VARS="ANTHROPIC_API_KEY LOG_LEVEL"
for var in $OPTIONAL_VARS; do
    if [ -z "${!var}" ]; then
        echo "ℹ️  Optional variable not set: $var"
    fi
done
