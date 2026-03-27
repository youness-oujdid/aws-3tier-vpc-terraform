# ── VPC ──────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private (app) subnets"
  value       = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the isolated DB subnets"
  value       = module.vpc.db_subnet_ids
}

# ── ALB ──────────────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Route53 Zone ID of the ALB (for alias records)"
  value       = module.alb.alb_zone_id
}

# ── RDS ──────────────────────────────────────────────────────────────
output "rds_endpoint" {
  description = "RDS PostgreSQL writer endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_read_replica_endpoint" {
  description = "RDS read-replica endpoint"
  value       = module.rds.db_read_endpoint
  sensitive   = true
}

# ── ElastiCache ──────────────────────────────────────────────────────
output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache.redis_endpoint
  sensitive   = true
}

# ── S3 ───────────────────────────────────────────────────────────────
output "s3_bucket_name" {
  description = "S3 bucket name for static assets"
  value       = module.s3.bucket_id
}

# ── CloudFront ───────────────────────────────────────────────────────
output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)"
  value       = module.cloudfront.distribution_id
}
