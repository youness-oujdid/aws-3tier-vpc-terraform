terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "youness-terraform-state"
    key            = "aws-3tier-vpc/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "youness-oujdid"
    }
  }
}

# ── VPC ──────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
}

# ── IAM ──────────────────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}

# ── S3 (static assets) ───────────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  project_name        = var.project_name
  environment         = var.environment
  cloudfront_oac_arn  = module.cloudfront.oac_arn
}

# ── ALB ──────────────────────────────────────────────────────────────
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = var.acm_certificate_arn
}

# ── AUTO SCALING GROUP ───────────────────────────────────────────────
module "asg" {
  source = "./modules/asg"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  alb_target_group_arn = module.alb.target_group_arn
  alb_security_group_id = module.alb.security_group_id
  instance_type        = var.instance_type
  ami_id               = var.ami_id
  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  desired_capacity     = var.asg_desired_capacity
  iam_instance_profile = module.iam.instance_profile_name
  user_data_script     = templatefile("${path.module}/scripts/user_data.sh", {
    environment  = var.environment
    db_endpoint  = module.rds.db_endpoint
    redis_endpoint = module.elasticache.redis_endpoint
  })
}

# ── RDS ──────────────────────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_ids        = module.vpc.db_subnet_ids
  app_security_group_id = module.asg.security_group_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_instance_class    = var.db_instance_class
  db_engine_version    = var.db_engine_version
  multi_az             = var.db_multi_az
  backup_retention     = var.db_backup_retention
}

# ── ELASTICACHE ──────────────────────────────────────────────────────
module "elasticache" {
  source = "./modules/elasticache"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_ids        = module.vpc.db_subnet_ids
  app_security_group_id = module.asg.security_group_id
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_nodes
}

# ── CLOUDFRONT ───────────────────────────────────────────────────────
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name    = var.project_name
  environment     = var.environment
  s3_bucket_id    = module.s3.bucket_id
  s3_bucket_domain = module.s3.bucket_regional_domain
  alb_dns_name    = module.alb.alb_dns_name
  domain_name     = var.domain_name
  certificate_arn = var.cloudfront_certificate_arn
}
