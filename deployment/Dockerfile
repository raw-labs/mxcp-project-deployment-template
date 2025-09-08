# UAE MXCP Server - Simple build following proven vertec pattern
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

# PROJECT-SPECIFIC: UAE Business License Data Preparation
# Squirro can modify this section for their data sources
ARG MXCP_DATA_ACCESS_KEY_ID
ARG MXCP_DATA_SECRET_ACCESS_KEY
ENV AWS_ACCESS_KEY_ID=$MXCP_DATA_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$MXCP_DATA_SECRET_ACCESS_KEY

# Download and process UAE business license data
RUN mkdir -p ./data ./logs
RUN python3 scripts/download_real_data.py --output data/licenses.csv
RUN dbt deps && dbt run --vars '{"licenses_file": "data/licenses.csv"}'

# Clear AWS credentials after data preparation (security)
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""

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