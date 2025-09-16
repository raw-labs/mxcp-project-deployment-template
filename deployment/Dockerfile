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

# Copy the entire project
COPY . .

# Create container-specific MXCP configuration
COPY deployment/mxcp-site-docker.yml ./mxcp-site.yml
COPY deployment/profiles-docker.yml ./profiles.yml

# Setup MXCP user configuration with secrets
RUN mkdir -p /home/mxcp/.mxcp
COPY deployment/mxcp-user-config.yml.template /home/mxcp/.mxcp/config.yml
RUN chown -R mxcp:mxcp /home/mxcp/.mxcp

# PROJECT-SPECIFIC: UAE Business License Data Preparation
# Squirro can modify this section for their data sources
ARG MXCP_DATA_ACCESS_KEY_ID
ARG MXCP_DATA_SECRET_ACCESS_KEY
ENV AWS_ACCESS_KEY_ID=$MXCP_DATA_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$MXCP_DATA_SECRET_ACCESS_KEY

# API keys for testing (needed for test-evals)
ARG OPENAI_API_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY

# Install just task runner for streamlined data preparation
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Prepare project data using justfile (supports different data strategies)
RUN mkdir -p ./data ./logs
# Use justfile for flexible data preparation - supports S3, API, or static data
RUN just prepare-build

# Create symlink for mxcp that tests expect
RUN mkdir -p .env/bin && ln -s /usr/local/bin/mxcp .env/bin/mxcp

# Set MXCP config path for tests (running as root during build)
ENV MXCP_CONFIG_PATH=/home/mxcp/.mxcp/config.yml

# Run all 3 levels of testing during build
# This ensures only tested code gets deployed
RUN just test-all || (echo "❌ Tests failed during Docker build" && exit 1)

# Clear sensitive credentials after tests (security)
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV OPENAI_API_KEY=""
ENV MXCP_CONFIG_PATH=""

# Ensure directories have correct permissions
RUN chmod -R 755 ./data ./logs && chown -R mxcp:mxcp ./data ./logs

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV MXCP_PROFILE=prod
ENV MXCP_TRANSPORT=streamable-http
ENV HOME=/home/mxcp
ENV DBT_PROFILES_DIR=/app
ENV PYTHONLOGLEVEL=INFO

# Switch to non-root user
USER mxcp

# Expose port
EXPOSE $PORT

# Copy and set up startup script
COPY --chown=mxcp:mxcp deployment/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Start the server
CMD ["/app/start.sh"]