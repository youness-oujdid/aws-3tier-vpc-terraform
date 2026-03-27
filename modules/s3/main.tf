# ──────────────────────────────────────────────────────────────────────
# S3 Module  (modules/s3/main.tf)
# ──────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "assets" {
  bucket        = "${var.project_name}-${var.environment}-static-assets"
  force_destroy = var.environment != "prod"
  tags          = { Name = "${var.project_name}-${var.environment}-static-assets" }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    id     = "transition-old-versions"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    noncurrent_version_expiration { noncurrent_days = 90 }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.assets.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = var.cloudfront_oac_arn
        }
      }
    }]
  })
}

variable "project_name"       { type = string }
variable "environment"        { type = string }
variable "cloudfront_oac_arn" { type = string default = "" }

output "bucket_id"              { value = aws_s3_bucket.assets.id }
output "bucket_arn"             { value = aws_s3_bucket.assets.arn }
output "bucket_regional_domain" { value = aws_s3_bucket.assets.bucket_regional_domain_name }
