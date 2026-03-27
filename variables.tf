# ── General ──────────────────────────────────────────────────────────
variable "project_name" {
  description = "Name prefix used for all resources"
  type        = string
  default     = "youness-3tier"
}

variable "environment" {
  description = "Deployment environment (prod | staging | dev)"
  type        = string
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be prod, staging, or dev."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

# ── Networking ───────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (must match subnet lists)"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (ALB, NAT Gateway)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (EC2 app tier)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDRs for isolated DB subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

# ── EC2 / ASG ────────────────────────────────────────────────────────
variable "ami_id" {
  description = "AMI ID for EC2 launch template (Amazon Linux 2023)"
  type        = string
  default     = "ami-0c38b837cd80f13bb"
}

variable "instance_type" {
  description = "EC2 instance type for the app tier"
  type        = string
  default     = "t3.medium"
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances at launch"
  type        = number
  default     = 2
}

# ── RDS ──────────────────────────────────────────────────────────────
variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master DB username (password managed by Secrets Manager)"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "db_backup_retention" {
  description = "Number of days to retain automated RDS backups"
  type        = number
  default     = 7
}

# ── ElastiCache ──────────────────────────────────────────────────────
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 2
}

# ── TLS / DNS ────────────────────────────────────────────────────────
variable "domain_name" {
  description = "Root domain name (e.g. example.com)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS listener (eu-west-1)"
  type        = string
  default     = ""
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be in us-east-1)"
  type        = string
  default     = ""
}
