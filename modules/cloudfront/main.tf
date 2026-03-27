resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-${var.environment}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : []

  # ── S3 origin (static assets) ──
  origin {
    domain_name              = var.s3_bucket_domain
    origin_id                = "S3-${var.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # ── ALB origin (dynamic API) ──
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-${var.project_name}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ── Default: route /api/* to ALB ──
  default_cache_behavior {
    target_origin_id       = "ALB-${var.project_name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE","GET","HEAD","OPTIONS","PATCH","POST","PUT"]
    cached_methods         = ["GET","HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization","Host","Origin"]
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # ── /static/* → S3 ──
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "S3-${var.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET","HEAD","OPTIONS"]
    cached_methods         = ["GET","HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == ""
    acm_certificate_arn            = var.certificate_arn != "" ? var.certificate_arn : null
    ssl_support_method             = var.certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  tags = { Name = "${var.project_name}-${var.environment}-cdn" }
}

variable "project_name"     { type = string }
variable "environment"      { type = string }
variable "s3_bucket_id"     { type = string }
variable "s3_bucket_domain" { type = string }
variable "alb_dns_name"     { type = string }
variable "domain_name"      { type = string default = "" }
variable "certificate_arn"  { type = string default = "" }

output "distribution_domain" { value = aws_cloudfront_distribution.main.domain_name }
output "distribution_id"     { value = aws_cloudfront_distribution.main.id }
output "oac_arn"             { value = aws_cloudfront_origin_access_control.main.arn }
