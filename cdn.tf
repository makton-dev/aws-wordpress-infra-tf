#############################################################################
# This manages Cloudfront CDN for the wordpress site
#############################################################################

resource "aws_cloudfront_distribution" "cdn" {
  # Cannot made the CDN with a valid certificate
  count = var.certs_validated ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for WordPress Site"
  default_root_object = "index.php"
  aliases             = [var.domain_name]
  price_class         = var.cdn_price_class

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = var.cdn_geo_whitelist
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.site_cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.1_2016"
  }

  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    domain_name = aws_acm_certificate.alb_cert.domain_name
    origin_id   = aws_lb.alb.dns_name
  }

  ## Default Caching for WordPress
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.alb.dns_name

    forwarded_values {
      query_string = true
      headers      = ["Origin", "CloudFront-Forwarded-Proto", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Is-Desktop-Viewer", "Authorization"] # "Host"

      cookies {
        forward           = "whitelist"
        whitelisted_names = var.whitelisted_cookies
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 1
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  ## Caching rules when in Admin part of Wordpress
  ordered_cache_behavior {
    path_pattern     = "wp-admin/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_lb.alb.dns_name

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ## Caching rules for the static content
  ordered_cache_behavior {
    path_pattern     = "wp-content/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.alb.dns_name

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ## caching rules for Includes folder
  ordered_cache_behavior {
    path_pattern     = "wp-includes/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.alb.dns_name

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  tags = {
    Name = "${var.project_name}-cdn"
  }
}
