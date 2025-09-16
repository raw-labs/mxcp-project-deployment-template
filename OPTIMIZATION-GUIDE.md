# MXCP Template Optimization Guide

This guide provides recommendations for optimizing your MXCP deployment for performance, security, and cost efficiency.

## 🚀 Performance Optimizations

### 1. Docker Image Optimization

#### Multi-Stage Build (50% size reduction)
```dockerfile
# Stage 1: Build and data preparation
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
# Data preparation here...

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/data ./data
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# Only runtime files...
```

#### Layer Caching
- Copy requirements.txt first, then code
- Group RUN commands to reduce layers
- Use .dockerignore to exclude unnecessary files

### 2. Data Loading Optimization

#### DuckDB Performance
```python
# In your models, use these settings for better performance:
SET memory_limit = '6GB';  # Adjust based on instance
SET threads = 4;           # Match vCPU count
SET preserve_insertion_order = false;  # Faster imports
```

#### Data Partitioning
- For large datasets (>1GB), partition by date or category
- Use Parquet format for 10x compression and faster queries

### 3. App Runner Configuration

#### Right-Sizing Instances
| Data Size | Recommended Config | Monthly Cost |
|-----------|-------------------|--------------|
| < 100MB   | 0.25 vCPU, 0.5GB | ~$10 |
| 100MB-1GB | 0.5 vCPU, 1GB | ~$20 |
| 1GB-10GB  | 1 vCPU, 2GB | ~$40 |
| 10GB-50GB | 2 vCPU, 4GB | ~$80 |
| > 50GB    | 4 vCPU, 8GB | ~$160 |

#### Auto-Scaling Configuration
```bash
# In deployment script, add:
--auto-scaling-configuration '{
    "MinSize": 1,
    "MaxSize": 3,
    "TargetCpu": 70,
    "TargetMemory": 80
}'
```

## 🔒 Security Hardening

### 1. Secrets Management

#### Use AWS Secrets Manager
```python
# Instead of environment variables:
import boto3
secrets_client = boto3.client('secretsmanager')
response = secrets_client.get_secret_value(SecretId='mxcp/api-keys')
secrets = json.loads(response['SecretString'])
```

### 2. Network Security

#### VPC Integration
```bash
# Add to App Runner configuration:
--network-configuration '{
    "EgressConfiguration": {
        "EgressType": "VPC",
        "VpcConnectorArn": "arn:aws:apprunner:region:account:vpcconnector/name"
    }
}'
```

### 3. Audit Logging

#### Enhanced Logging
```python
# In start.sh, add structured logging:
import json
import logging

class AuditFilter(logging.Filter):
    def filter(self, record):
        # Redact sensitive data
        if hasattr(record, 'msg'):
            record.msg = self.redact_secrets(record.msg)
        return True
```

## 💰 Cost Optimization

### 1. Data Storage

#### S3 Lifecycle Policies
```json
{
    "Rules": [{
        "Id": "ArchiveOldData",
        "Status": "Enabled",
        "Transitions": [{
            "Days": 30,
            "StorageClass": "INTELLIGENT_TIERING"
        }]
    }]
}
```

### 2. Compute Optimization

#### Scheduled Scaling
```python
# Scale down during off-hours
def get_instance_config():
    hour = datetime.now().hour
    if 9 <= hour <= 18:  # Business hours
        return {"cpu": "2 vCPU", "memory": "4GB"}
    else:
        return {"cpu": "0.5 vCPU", "memory": "1GB"}
```

### 3. LLM Cost Management

#### Token Optimization
```python
# Cache common queries
from functools import lru_cache

@lru_cache(maxsize=1000)
def cached_llm_query(prompt_hash):
    return llm.complete(prompt)

# Use smaller models for simple tasks
def select_model(complexity):
    if complexity == "simple":
        return "gpt-3.5-turbo"  # 10x cheaper
    return "gpt-4o"
```

## 🎯 Monitoring & Observability

### 1. CloudWatch Dashboards

Create a dashboard with:
- Request latency (p50, p90, p99)
- Error rate
- Memory/CPU utilization
- Data query performance
- LLM token usage

### 2. Alerts

Set up alerts for:
- Error rate > 1%
- Response time > 2s (p99)
- Memory usage > 80%
- Failed deployments

### 3. Performance Profiling

```python
# Add to your tools:
import cProfile
import pstats

def profile_endpoint(func):
    def wrapper(*args, **kwargs):
        profiler = cProfile.Profile()
        profiler.enable()
        result = func(*args, **kwargs)
        profiler.disable()
        
        # Log top 10 time consumers
        stats = pstats.Stats(profiler)
        stats.sort_stats('cumulative')
        stats.print_stats(10)
        
        return result
    return wrapper
```

## 🔧 Development Workflow Optimization

### 1. Local Development

Use docker-compose for fast iteration:
```bash
docker-compose up --build
# Hot reload enabled for tools/
```

### 2. CI/CD Pipeline

#### Parallel Testing
```yaml
test:
  parallel:
    matrix:
      test-type: [config, data, integration]
    steps:
      - run: just test-${{ matrix.test-type }}
```

#### Build Caching
```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.cache/pip
      ./data/cache
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

## 📊 Data Pipeline Optimization

### 1. Incremental Processing

```sql
-- In your dbt models
{{ config(
    materialized='incremental',
    unique_key='id',
    on_schema_change='merge'
) }}

SELECT * FROM source_data
{% if is_incremental() %}
WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
```

### 2. Query Optimization

```python
# Use prepared statements
conn.execute("""
    PREPARE my_query AS
    SELECT * FROM licenses
    WHERE emirate_name_en = $1
    LIMIT $2
""")

# Execute many times efficiently
results = conn.execute("EXECUTE my_query('Dubai', 100)")
```

## 🎭 A/B Testing

### Feature Flags
```python
# Enable gradual rollouts
def get_feature_flag(feature, user_id=None):
    if feature == "new_llm_model":
        # 10% rollout
        return hash(user_id) % 10 == 0
    return False
```

## 📈 Scaling Considerations

### When to Consider Alternative Architectures

| Metric | Current Limit | Next Architecture |
|--------|--------------|-------------------|
| Data Size | 100GB | Move to Snowflake/BigQuery |
| Concurrent Users | 100 | Add Redis caching layer |
| Queries/sec | 50 | Implement read replicas |
| LLM calls/min | 100 | Add queue system (SQS) |

Remember: Optimize only when needed. Measure first, optimize second.
