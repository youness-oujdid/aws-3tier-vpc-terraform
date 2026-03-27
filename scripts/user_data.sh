#!/bin/bash
set -euo pipefail

# ── Variables injected by Terraform templatefile ──────────────────────
ENVIRONMENT="${environment}"
DB_ENDPOINT="${db_endpoint}"
REDIS_ENDPOINT="${redis_endpoint}"

# ── System updates ────────────────────────────────────────────────────
dnf update -y
dnf install -y docker amazon-cloudwatch-agent jq aws-cli

# ── Docker ────────────────────────────────────────────────────────────
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ── Fetch secrets from AWS Secrets Manager ────────────────────────────
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
PROJECT_NAME=$(aws ssm get-parameter \
  --name "/project/name" --region "$REGION" \
  --query "Parameter.Value" --output text 2>/dev/null || echo "youness-3tier")

DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$PROJECT_NAME/$ENVIRONMENT/db-password" \
  --region "$REGION" --query SecretString --output text)

DB_PASSWORD=$(echo "$DB_SECRET" | jq -r .password)
DB_USER=$(echo "$DB_SECRET"     | jq -r .username)

REDIS_AUTH=$(aws secretsmanager get-secret-value \
  --secret-id "$PROJECT_NAME/$ENVIRONMENT/redis-auth-token" \
  --region "$REGION" --query SecretString --output text)

# ── Write app environment file ────────────────────────────────────────
cat > /etc/app.env <<EOF
ENVIRONMENT=$ENVIRONMENT
DB_HOST=$DB_ENDPOINT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=appdb
REDIS_HOST=$REDIS_ENDPOINT
REDIS_PORT=6379
REDIS_AUTH=$REDIS_AUTH
EOF
chmod 600 /etc/app.env

# ── CloudWatch Agent config ───────────────────────────────────────────
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "agent": { "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/*.log",
            "log_group_name": "/app/{environment}/application",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "App/{environment}",
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_idle","cpu_usage_user","cpu_usage_system"], "metrics_collection_interval": 60 },
      "mem": { "measurement": ["mem_used_percent"], "metrics_collection_interval": 60 },
      "disk": { "measurement": ["used_percent"], "resources": ["/"], "metrics_collection_interval": 60 }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "Bootstrap complete — environment: $ENVIRONMENT"
