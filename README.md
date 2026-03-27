# aws-3tier-vpc-terraform

> Production-grade 3-tier AWS VPC architecture fully provisioned with Terraform. Designed for high availability across 3 Availability Zones with zero-downtime deployments.

![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?style=flat-square&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-eu--west--1-FF9900?style=flat-square&logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## Architecture

```
                         Internet
                            │
                    [Route53 DNS]
                            │
              [CloudFront CDN + WAF]
              /                    \
     [S3 Static Assets]      [ALB - HTTPS/443]
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
         eu-west-1a            eu-west-1b            eu-west-1c
      ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
      │ Public Subnet │     │ Public Subnet │     │ Public Subnet │
      │  NAT Gateway  │     │  NAT Gateway  │     │  NAT Gateway  │
      └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
             │                   │                     │
      ┌──────▼───────┐     ┌──────▼───────┐     ┌──────▼───────┐
      │Private Subnet │     │Private Subnet │     │Private Subnet │
      │   EC2 (ASG)   │     │   EC2 (ASG)   │     │   EC2 (ASG)   │
      └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
             │                   │                     │
      ┌──────▼───────────────────▼─────────────────────▼───────┐
      │                    DB Subnets (Isolated)                 │
      │        [RDS PostgreSQL Multi-AZ]  [ElastiCache Redis]   │
      └──────────────────────────────────────────────────────────┘
```

---

## Modules

| Module | Description |
|---|---|
| `modules/vpc` | VPC, subnets (public / private / DB), IGW, NAT GWs, route tables, VPC Flow Logs |
| `modules/alb` | Application Load Balancer, HTTPS listener, HTTP→HTTPS redirect, access logs |
| `modules/asg` | Launch template (IMDSv2, encrypted EBS), Auto Scaling Group, CPU scaling policies |
| `modules/rds` | PostgreSQL 15 Multi-AZ, read replica (prod), Secrets Manager password, enhanced monitoring |
| `modules/elasticache` | Redis replication group, encryption at rest + in-transit, auth token in Secrets Manager |
| `modules/s3` | Static assets bucket, versioning, SSE-S3, lifecycle (IA → Glacier), CloudFront OAC policy |
| `modules/cloudfront` | Distribution with S3 + ALB origins, caching behaviors, custom error pages |
| `modules/iam` | EC2 instance profile, SSM Session Manager, CloudWatch Agent, least-privilege S3/Secrets policies |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate credentials
- S3 bucket for Terraform state (update `backend "s3"` in `main.tf`)
- DynamoDB table for state locking (`terraform-state-lock`)

---

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/youness-oujdid/aws-3tier-vpc-terraform.git
cd aws-3tier-vpc-terraform
```

### 2. Create S3 backend resources

```bash
# Create state bucket
aws s3api create-bucket \
  --bucket youness-terraform-state \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

# Enable versioning on state bucket
aws s3api put-bucket-versioning \
  --bucket youness-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Deploy to staging

```bash
terraform plan \
  -var-file="environments/staging/terraform.tfvars" \
  -out=tfplan

terraform apply tfplan
```

### 5. Deploy to production

```bash
terraform plan \
  -var-file="environments/prod/terraform.tfvars" \
  -out=tfplan

terraform apply tfplan
```

---

## CI/CD Pipeline

The included GitHub Actions workflow (`.github/workflows/terraform.yml`) runs on every PR and push:

```
push / PR → validate → fmt check → tfsec scan → checkov scan
                                                      │
                                              terraform plan
                                              (posted as PR comment)
                                                      │
                                  manual trigger → terraform apply
```

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN` | IAM role ARN for GitHub Actions OIDC authentication |

---

## Security Features

- **IMDSv2 enforced** on all EC2 instances (no IMDSv1)
- **Encrypted EBS volumes** on all instances
- **Encryption at rest** for RDS and ElastiCache
- **Transit encryption** for Redis (TLS + auth token)
- **Secrets Manager** for all credentials (no plaintext in config)
- **VPC Flow Logs** → CloudWatch for network audit
- **S3 public access blocked** — assets served only via CloudFront OAC
- **Least-privilege IAM** — EC2 can only read its own secrets

---

## Tear Down

```bash
terraform destroy \
  -var-file="environments/staging/terraform.tfvars"
```

> ⚠️ Production has `deletion_protection = true` on RDS and ALB — disable these manually before destroying.

---

## Author

**Youness OUJDID** — Senior DevOps & Cloud Engineer

[![Portfolio](https://img.shields.io/badge/Portfolio-youness--oujdid.github.io-00d4ff?style=flat-square)](https://github.com/youness-oujdid)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/youness-oujdid-2250b0139/)
