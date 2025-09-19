# MXCP Server - Generic build template
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Create non-root user
RUN groupadd -r mxcp && useradd -r -g mxcp -m -d /home/mxcp mxcp

# Copy requirements first for better caching
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Document runtime environment variables (injected by App Runner)
LABEL env.runtime.OPENAI_API_KEY='{"required": true, "type": "secret", "description": "OpenAI API key for LLM calls", "example": "sk-..."}'
LABEL env.runtime.ANTHROPIC_API_KEY='{"required": false, "type": "secret", "description": "Anthropic API key for Claude models", "example": "sk-ant-..."}'
LABEL env.runtime.VERTEC_API_KEY='{"required": false, "type": "secret", "description": "Vertec API key (API projects only)", "example": "vtc_..."}'

# Document CI/CD environment variables (used during deployment only)
LABEL env.cicd.AWS_ACCESS_KEY_ID='{"required": true, "type": "secret", "description": "AWS access key for deployment", "example": "AKIA..."}'
LABEL env.cicd.AWS_SECRET_ACCESS_KEY='{"required": true, "type": "secret", "description": "AWS secret key for deployment", "example": "..."}'
LABEL env.cicd.MXCP_DATA_ACCESS_KEY_ID='{"required": false, "type": "secret", "description": "AWS key for S3 data download", "example": "AKIA..."}'
LABEL env.cicd.MXCP_DATA_SECRET_ACCESS_KEY='{"required": false, "type": "secret", "description": "AWS secret for S3 data download", "example": "..."}'

# Copy the entire project
COPY . .

# Create container-specific MXCP configuration
COPY deployment/mxcp-site-docker.yml ./mxcp-site.yml
COPY deployment/profiles-docker.yml ./profiles.yml
COPY deployment/mxcp-user-config.yml /home/mxcp/.mxcp/config.yml

# Install just task runner (needs root for /usr/local/bin)
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Change ownership of everything to mxcp user
RUN chown -R mxcp:mxcp /app /home/mxcp

# Switch to non-root user for security
USER mxcp

# Create required directories
RUN mkdir -p ./data ./logs .env/bin

# Create symlink for mxcp that tests expect
RUN ln -s /usr/local/bin/mxcp .env/bin/mxcp

# Build dbt models with the data that was downloaded outside Docker
RUN just build-models || (echo "❌ dbt model build failed" && exit 1)

# Run only build-safe tests during build (no API keys required)
# Full testing happens after build with runtime secrets
RUN just test-config || (echo "❌ Config validation failed during Docker build" && exit 1)

# Ensure directories have correct permissions
RUN chmod -R 755 ./data ./logs

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV MXCP_PROFILE=prod
ENV MXCP_TRANSPORT=streamable-http
ENV HOME=/home/mxcp
ENV DBT_PROFILES_DIR=/app
ENV PYTHONLOGLEVEL=INFO

# Expose port
EXPOSE $PORT

# Copy and set up startup script
COPY --chown=mxcp:mxcp deployment/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Start the server
CMD ["/app/start.sh"]